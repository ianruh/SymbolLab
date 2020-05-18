//
//  File.swift
//  
//
//  Created by Ian Ruh on 5/14/20.
//

import SymEngine

//############################ Protocol and Precendence Definitions ##################

internal enum OperationAssociativity {
    case left, none, right
}

internal enum OperationType {
    case prefix, infix, postfix, function
}

internal class OperationPrecedence: Comparable {
    var higherThan: OperationPrecedence?
    
    init(higherThan: OperationPrecedence?) {
        self.higherThan = higherThan
    }
    
    func getLevel() -> Int {
        var count: Int = 0
        var current: OperationPrecedence = self
        while(current.higherThan != nil) {
            count += 1
            current = current.higherThan!
        }
        return count
    }
    
    static func < (lhs: OperationPrecedence, rhs: OperationPrecedence) -> Bool {
        return lhs.getLevel() < rhs.getLevel()
    }
    
    static func == (lhs: OperationPrecedence, rhs: OperationPrecedence) -> Bool {
        return lhs.getLevel() == rhs.getLevel()
    }
}

internal protocol Operation: Node {
    var precedence: OperationPrecedence {get}
    var type: OperationType {get}
    var associativity: OperationAssociativity {get}
    var identifier: String {get}
    
    init(_ params: [Node])
    
    func factory(_ params: [Node]) -> Node
}

// Useless, this is a hack
internal struct Op: Operation {
    var precedence: OperationPrecedence = OperationPrecedence(higherThan: nil)
    var type: OperationType = .infix
    var associativity: OperationAssociativity = .none
    var identifier: String = ""
    init(_ params: [Node]) {}
    func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
    public var symbol: Symbol? = nil
    public var description: String = ""
}

internal let P = Op([])

//############################ Basic Operations #############################

/**
Assign one node to the other.
*/
public struct Assign: Operation {
    
    // Nil means is the lowest possible precedence
    internal let precedence: OperationPrecedence = OperationPrecedence(higherThan: nil)
    internal let type: OperationType = .infix
    internal let associativity: OperationAssociativity = .none
    internal let identifier: String = "="
    
    // Store the parameters for the node
    private var left: Node
    private var right: Node
    
    public var description: String {
        // This is always true
        return "\(self.left)=\(self.right)"
    }
    
    public var symbol: Symbol? {
        // There is no corresponding representation in SymEngine
        return nil
    }
    
    init(_ params: [Node]) {
        self.left = params[0]
        self.right = params[1]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
}

/**
A negative number
*/
public struct Negative: Operation {
    internal let precedence: OperationPrecedence = OperationPrecedence(higherThan: Parentheses([P,P]).precedence)
    internal let type: OperationType = .prefix
    internal let associativity: OperationAssociativity = .none
    internal let identifier: String = "-"
    
    // Store the parameters for the node
    private var argument: Node
    
    public var description: String {
        return "-\(self.argument)"
    }
    
    public var symbol: Symbol? {
        return SymEngine.neg(self.argument.symbol)
    }
    
    init(_ params: [Node]) {
        self.argument = params[0]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
}

/**
A decimal number
*/
public struct Decimal: Operation {
    internal let precedence: OperationPrecedence = OperationPrecedence(higherThan: Negative([P,P]).precedence)
    internal let type: OperationType = .infix
    internal let associativity: OperationAssociativity = .none
    internal let identifier: String = "."
    
    // Store the parameters for the node
    private var left: Node
    private var right: Node
    
    public var description: String {
        guard let leftNumber = self.left as? Number else {
            print("Missused decimal operation : '\(self.left).\(self.right)'")
            return ""
        }
        guard let rightNumber = self.right as? Number else {
            print("Missused decimal operation : '\(self.left).\(self.right)'")
            return ""
        }
        return "\(leftNumber).\(rightNumber)"
    }
    
    public var symbol: Symbol? {
        guard let leftNumber = self.left as? Number else {return nil}
        guard let rightNumber = self.right as? Number else {return nil}
        let valueOpt: Double? = Double("\(leftNumber).\(rightNumber)")
        if let value = valueOpt {
            return Symbol(value)
        }
        return nil
    }
    
    init(_ params: [Node]) {
        self.left = params[0]
        self.right = params[1]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
}

/**
Add one node to the other.
*/
public struct Add: Operation {
    
    internal let precedence: OperationPrecedence = OperationPrecedence(higherThan: Assign([P,P]).precedence)
    internal let type: OperationType = .infix
    internal let associativity: OperationAssociativity = .left
    internal let identifier: String = "+"
    
    // Store the parameters for the node
    private var left: Node
    private var right: Node
    
    public var description: String {
        var leftString = "\(self.left)"
        var rightString = "\(self.right)"
        
        // Wrap the sides if needed
        if let op = self.left as? Operation {
            if(op.precedence < self.precedence && op.type == .infix) {
                leftString = "(\(leftString))"
            }
        }
        if let op = self.right as? Operation {
            if(op.precedence < self.precedence && op.type == .infix) {
                rightString = "(\(leftString))"
            }
        }
        
        return "\(leftString)+\(rightString)"
    }
    
    public var symbol: Symbol? {
        return self.left.symbol + self.right.symbol
    }
    
    init(_ params: [Node]) {
        self.left = params[0]
        self.right = params[1]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
}

/**
Subtract one node from the other.
*/
public struct Subtract: Operation {
    
    internal let precedence: OperationPrecedence = OperationPrecedence(higherThan: Assign([P,P]).precedence)
    internal let type: OperationType = .infix
    internal let associativity: OperationAssociativity = .left
    internal let identifier: String = "-"
    
    // Store the parameters for the node
    private var left: Node
    private var right: Node
    
    public var description: String {
        var leftString = "\(self.left)"
        var rightString = "\(self.right)"
        
        // Wrap the sides if needed
        if let op = self.left as? Operation {
            if(op.precedence < self.precedence && op.type == .infix) {
                leftString = "(\(leftString))"
            }
        }
        if let op = self.right as? Operation {
            if(op.precedence < self.precedence && op.type == .infix) {
                rightString = "(\(leftString))"
            }
        }
        
        return "\(leftString)-\(rightString)"
    }
    
    public var symbol: Symbol? {
        return self.left.symbol - self.right.symbol
    }
    
    init(_ params: [Node]) {
        self.left = params[0]
        self.right = params[1]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
}

/**
Multiply one node by the other.
*/
public struct Multiply: Operation {
    
    internal let precedence: OperationPrecedence = OperationPrecedence(higherThan: Add([P,P]).precedence)
    internal let type: OperationType = .infix
    internal let associativity: OperationAssociativity = .left
    internal let identifier: String = "*"
    
    // Store the parameters for the node
    private var left: Node
    private var right: Node
    
    public var description: String {
        var leftString = "\(self.left)"
        var rightString = "\(self.right)"
        
        // Wrap the sides if needed
        if let op = self.left as? Operation {
            if(op.precedence < self.precedence && op.type == .infix) {
                leftString = "(\(leftString))"
            }
        }
        if let op = self.right as? Operation {
            if(op.precedence < self.precedence && op.type == .infix) {
                rightString = "(\(leftString))"
            }
        }
        
        return "\(leftString)*\(rightString)"
    }
    
    public var symbol: Symbol? {
        return self.left.symbol * self.right.symbol
    }
    
    init(_ params: [Node]) {
        self.left = params[0]
        self.right = params[1]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
}

/**
Divide one node by the other.
*/
public struct Divide: Operation {
    
    internal let precedence: OperationPrecedence = OperationPrecedence(higherThan: Add([P,P]).precedence)
    internal let type: OperationType = .infix
    internal let associativity: OperationAssociativity = .left
    internal let identifier: String = "/"
    
    // Store the parameters for the node
    private var left: Node
    private var right: Node
    
    public var description: String {
        var leftString = "\(self.left)"
        var rightString = "\(self.right)"
        
        // Wrap the sides if needed
        if let op = self.left as? Operation {
            if(op.precedence < self.precedence && op.type == .infix) {
                leftString = "(\(leftString))"
            }
        }
        if let op = self.right as? Operation {
            if(op.precedence < self.precedence && op.type == .infix) {
                rightString = "(\(leftString))"
            }
        }
        
        return "\(leftString)/\(rightString)"
    }
    
    public var symbol: Symbol? {
        return self.left.symbol / self.right.symbol
    }
    
    init(_ params: [Node]) {
        self.left = params[0]
        self.right = params[1]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
}

/**
Power of one node to the other.
*/
public struct Power: Operation {
    
    internal let precedence: OperationPrecedence = OperationPrecedence(higherThan: Multiply([P,P]).precedence)
    internal let type: OperationType = .infix
    internal let associativity: OperationAssociativity = .right
    internal let identifier: String = "^"
    
    // Store the parameters for the node
    private var left: Node
    private var right: Node
    
    public var description: String {
        var leftString = "\(self.left)"
        var rightString = "\(self.right)"
        
        // Wrap the sides if needed
        if let op = self.left as? Operation {
            if(op.precedence < self.precedence && op.type == .infix) {
                leftString = "(\(leftString))"
            }
        }
        if let op = self.right as? Operation {
            if(op.precedence < self.precedence && op.type == .infix) {
                rightString = "(\(leftString))"
            }
        }
        
        return "\(leftString)^\(rightString)"
    }
    
    public var symbol: Symbol? {
        return self.left.symbol ** self.right.symbol
    }
    
    init(_ params: [Node]) {
        self.left = params[0]
        self.right = params[1]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
}

/**
Factorial of a node.
*/
public struct Factorial: Operation {
    
    internal let precedence: OperationPrecedence = OperationPrecedence(higherThan: Power([P,P]).precedence)
    internal let type: OperationType = .postfix
    internal let associativity: OperationAssociativity = .none
    internal let identifier: String = "!"
    
    // Store the parameters for the node
    private var argument: Node
    
    public var description: String {
        // Wrap if needed
        if let op = self.argument as? Operation {
            if(op.type != .function) {
                return "(\(self.argument))!"
            }
        }
        
        return "\(self.argument)!"
    }
    
    public var symbol: Symbol? {
        #warning("Factorial has not been implemented yet.")
        return nil
    }
    
    init(_ params: [Node]) {
        self.argument = params[0]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
}

