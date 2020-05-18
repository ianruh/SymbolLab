//
//  File.swift
//
//
//  Created by Ian Ruh on 5/9/20.
//

import Foundation

//##################### LISTS #######################

private let operations: [Operation] = [Assign([P,P]), Decimal([P,P]), Negative([P,P]), Add([P,P]), Subtract([P,P]), Multiply([P,P]), Divide([P,P]), Power([P,P]), Factorial([P]), Parentheses([P]), Derivative([P,P]), Integral([P,P,P,P]), Sin([P])]

private func getOperationGroups() -> [[Operation]] {
    let sortedOps = operations.sorted(by: {$0.precedence > $1.precedence})
    var groupedOps: [[Operation]] = []
    for op in sortedOps {
        // Add new list
        if(groupedOps.count == 0) {
            groupedOps.append([op])
            continue
        }

        // Append to current list
        if(groupedOps.last!.last!.precedence.getLevel() == op.precedence.getLevel()) {
            groupedOps[groupedOps.count-1].append(op)
        } else {
            groupedOps.append([op])
            continue
        }
    }
    return groupedOps
}

private func getIdentifierMap() -> [String: Operation] {
    var identifierMap: [String: Operation] = [:]
    for op in operations {
        identifierMap[op.identifier] = op
    }
    return identifierMap
}

private let groups = getOperationGroups()
private let identifiers = getIdentifierMap()

//#################### PARSERS ######################

private struct Token: CustomStringConvertible {
    var description: String {
        if let str = self.str {
            return str
        } else {
            return "$\(self.node!.description)"
        }
    }

    var str: String?
    var node: Node?
}

public struct Debug: CustomStringConvertible {
    let msg: String
    
    public var description: String {
        self.msg
    }
}

public struct Parser {
    
    private var debug: (String) -> ()
    
    public init(debugMessageHandler: ((String) -> ())? = nil) {
        if let debug = debugMessageHandler {
            self.debug = debug
        } else {
            self.debug = Parser.simplePrint
        }
    }
    
    private static func simplePrint(_ msg: String) {
        print(msg)
    }

    public func parse(cString strArg: String) -> Node? {
        let str = strArg.cleanWhiteSpace()
        // Do initial check of parentheses so we can asume they are fine later
        guard str.hasValidParetheses else {
            self.debug("String does not have matching sets of parentheses.")
            return nil
        }
        // Tokenize the string
        var tokens: [Token] = []
        var backlog: String = ""
        for c in str {
            // Add number to the backlog
            if(c.isNumber && (backlog.isInteger || backlog.isEmpty)) {
                backlog += String(c)
            } else if(c.isLetter && (backlog.isAlphabetic || backlog.isEmpty)) {
                backlog += String(c)
            } else {
                // Add backlog
                if(!backlog.isEmpty) {
                    if(backlog.isInteger && !c.isLetter) {
                        // Implicit conversion should never fail because checking is integer
                        tokens.append(Token(str: nil, node: Number(Int(backlog)!)))
                    } else if (backlog.isAlphabetic && !c.isNumber && c != "(") { // (c != "(") to catch 'sin(x)'
                        // Is letters
                        tokens.append(Token(str: nil, node: Variable(backlog)))
                    } else if (backlog.isAlphabetic && c == "(") {
                        // Is a function
                        tokens.append(Token(str: "\(backlog)(", node: nil))
                        backlog = ""
                        continue
                    } else {
                        self.debug("Implicit multiplication of '\(backlog)' and '\(c)' is not allowed.")
                        return nil
                    }
                    backlog = "" // Clear backlog for future use
                }
                tokens.append(Token(str: String(c), node: nil))
            }
        }
        // Add backlog if empty (special case for end of string)
        if(!backlog.isEmpty) {
            if(backlog.isInteger) {
                // Implicit conversion should never fail because checking is integer
                tokens.append(Token(str: nil, node: Number(Int(backlog)!)))
            } else {
                // Is letters
                tokens.append(Token(str: nil, node: Variable(backlog)))
            }
            backlog = "" // Clear backlog for future use
        }

        // Recursively parse the expression
        tokens = parseCStringToken(tokens)
        if(tokens.count == 1) {
            return tokens[0].node
        } else if(tokens.count == 0) {
            // We ended up with no tokens and message was already printed.
            return nil
        } else {
            self.debug("Token parsing ended with multiple tokens: \(tokens)")
            return nil
        }
    }

    /**
     The length of the return value should always be checked. If no tokens are returned, then an error occured and
     a debug message was sent.
     */
    private func parseCStringToken(_ tokensArg: [Token]) -> [Token] {
        var tokens = tokensArg
        // Go through all of the groups in order of decreasing precendence
        for group in groups {
            // Loop through each group
            for op in group {
                // handle depending on the type of operation
                switch op.type {
                case .prefix:
                    // Look through the tokens
                    var i = 0
                    while(i < tokens.count) {
                        guard let str = tokens[i].str else {
                            i+=1
                            continue
                        }
                        if(str == op.identifier) {
                            guard i+1 < tokens.count else {
                                self.debug("Prefix operation '\(op.identifier)' has no operand.")
                                return []
                            }
                            guard let param = tokens[i+1].node else {
                                self.debug("Prefix operation '\(op.identifier)' cannot act on '\(tokens[i+1].str!)'")
                                return []
                            }
                            // Special case for negative
                            if(op.identifier == "-" &&  i > 0) {
                                // previous thing is a node, so this is subtraction, not negative
                                if(tokens[i-1].node != nil) {
                                    i += 1
                                    continue
                                }
                            }
                            let newNode = op.factory([param])
                            tokens.replaceSubrange(i...i+1, with: [Token(str: nil, node: newNode)])
                            i -= 1 // Because we went from two nodes to 1
                        }
                        i += 1
                    }
                case .infix:
                    // Look through the tokens
                    var i = 0
                    var progressStep = 1
                    if(op.associativity == .right) {
                        // Go though the tokens right to left
                        i = tokens.count-1
                        progressStep = -1
                    }
                    while((op.associativity != .right && i < tokens.count) ||
                        (op.associativity == .right && i > -1)) {
                        guard let str = tokens[i].str else {
                            i+=progressStep
                            continue
                        }
                        if(str == op.identifier) {
                            guard i+1 < tokens.count else {
                                self.debug("Infix operation '\(op.identifier)' has no second operand.")
                                return []
                            }
                            guard i-1 > -1 else {
                                self.debug("Infix operation '\(op.identifier)' has no first operand.")
                                return []
                            }
                            guard let left = tokens[i-1].node else {
                                self.debug("Infix operation '\(op.identifier)' cannot act on '\(tokens[i-1].str!)'")
                                return []
                            }
                            guard let right = tokens[i+1].node else {
                                self.debug("Infix operation '\(op.identifier)' cannot act on '\(tokens[i+1].str!)'")
                                return []
                            }
                            
                            // Special case to disallow chaining of decimals
                            if(op.identifier == "." && ((left as? Decimal) != nil || (right as? Decimal) != nil)) {
                                self.debug("Decimals cannot be chained.")
                                return []
                            }
                            let newNode = op.factory([left, right])
                            tokens.replaceSubrange(i-1...i+1, with: [Token(str: nil, node: newNode)])
                            
                            // We don't need to adjust when going right to left
                            if(op.associativity != .right) {
                                i -= 2 // Because we just coalesced three tokens into one
                            }
                        }
                        i += progressStep
                    }
                case .postfix:
                    // Look through the tokens
                    var i = 0
                    while(i < tokens.count) {
                        guard let str = tokens[i].str else {
                            i+=1
                            continue
                        }
                        if(str == op.identifier) {
                            guard i-1 > -1 else {
                                self.debug("Postfix operation '\(op.identifier)' has no operand.")
                                return []
                            }
                            guard let param = tokens[i-1].node else {
                                self.debug("Postfix operation '\(op.identifier)' cannot act on '\(tokens[i-1].str!)'")
                                return []
                            }
                            let newNode = op.factory([param])
                            tokens.replaceSubrange(i-1...i, with: [Token(str: nil, node: newNode)])
                            i -= 1 // Because we went from two nodes to 1
                        }
                        i += 1
                    }
                case .function:
                    // Look through the tokens
                    guard let fu = op as? Function else {
                        self.debug("Malformed function. Function type must be '.function'")
                        return []
                    }
                    
                    // Find outermost pair of parentheses
                    let firstIndexOpt: Int? = tokens.firstIndex(where: {$0.str != nil && $0.str!.contains("(")})
                    
                    // No parenthese to parse
                    guard let firstIndex = firstIndexOpt else { continue }
                    
                    // find the corresponding parenthese
                    var lastIndex = 0
                    var count = 0
                    for i in firstIndex..<tokens.count {
                        if let str = tokens[i].str {
                            if(str.contains("(")) {
                                count += 1
                            } else if(str == ")") {
                                count -= 1
                            }
                            
                            // Found corresponding parenthese
                            if(count == 0) {
                                lastIndex = i
                                break
                            }
                        }
                    }
                    
                    // Empty  function
                    guard lastIndex - firstIndex > 1 else {
                        self.debug("Empty functions are not allowed")
                        return []
                    }
                    
                    let str = tokens[firstIndex].str!.dropLast()
                    if(str == fu.identifier) {
                        // This is ours, parse it
                        var paramTokens: [Token] = self.parseCStringToken(Array<Token>(tokens[firstIndex+1..<lastIndex]))
                        guard paramTokens.count != 0 else {
                            // An error message was already sent, just propogate the error
                            return []
                        }
                        let withCommaCount =  paramTokens.count
                        // We need to remove the commas
                        paramTokens.removeAll(where: {$0.str != nil && $0.str! == ","})
                        // Verify we don't have a dangling comma or comma duplicates
                        guard withCommaCount-fu.numArguments+1 == paramTokens.count else {
                            self.debug("Duplicate or dangling commas are not allowed.")
                            return []
                        }
                        
                        guard paramTokens.count == fu.numArguments else {
                            self.debug("Function '\(fu.identifier)' must have \(fu.numArguments) but was given \(paramTokens.count)")
                            return []
                        }
                        var params: [Node] = []
                        for token in paramTokens {
                            guard let node = token.node else {
                                self.debug("Unable to process function because non-node tokens were found.")
                                return []
                            }
                            params.append(node)
                        }
                        
                        // Replace the node
                        let newNode: Node = fu.factory(params)
                        tokens.replaceSubrange(firstIndex...lastIndex, with: [Token(str: nil, node: newNode)])
                        
                        // Parse the rest of the tokens (in case we have (1+2)*(1-2), where we have parsed
                        // the first pair, but not the second.
                        tokens = self.parseCStringToken(tokens)
                    }
                        
                    
                }
            }
        }
        return tokens
    }
}
