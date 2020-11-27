//
//  File.swift
//  
//
//  Created by Ian Ruh on 5/14/20.
//

import Foundation
import Numerics

//############################ Protocol and Precendence Definitions ##################

public enum OperationAssociativity {
    case left, none, right
}

public enum OperationType {
    case prefix, infix, postfix, function
}

/// Operation precedence struct.
public class OperationPrecedence: Comparable {
    var higherThan: OperationPrecedence?
    
    init(higherThan: OperationPrecedence?) {
        self.higherThan = higherThan
    }
    
    public func getLevel() -> Int {
        var count: Int = 0
        var current: OperationPrecedence = self
        while(current.higherThan != nil) {
            count += 1
            current = current.higherThan!
        }
        return count
    }
    
    public static func < (lhs: OperationPrecedence, rhs: OperationPrecedence) -> Bool {
        return lhs.getLevel() < rhs.getLevel()
    }
    
    public static func == (lhs: OperationPrecedence, rhs: OperationPrecedence) -> Bool {
        return lhs.getLevel() == rhs.getLevel()
    }
}

/// The basic properties all opertaions need to have (plus a factory function)
public protocol Operation: Node {
    var precedence: OperationPrecedence {get}
    var type: OperationType {get}
    var associativity: OperationAssociativity {get}
    var identifier: String {get}
    
    init(_ params: [Node])
    init()
}

extension Operation {
    init(_ params: Node...) {
        self.init(params)
    }
}

//############################ Basic Operations #############################

/// Assign one node to the other.
public class Assign: Node, Operation {
    // Nil means is the lowest possible precedence
    public let precedence: OperationPrecedence = OperationPrecedence(higherThan: nil)
    public let type: OperationType = .infix
    public let associativity: OperationAssociativity = .none
    public let identifier: String = "="
    
    // Store the parameters for the node
    public var left: Node
    public var right: Node
    
    override public var description: String {
        // This is always true
        return "\(self.left)=\(self.right)"
    }
    
    override public var latex: String {
        return "\(self.left.latex)=\(self.right.latex)"
    }
    
    override public var variables: Set<Variable> {
        return self.left.variables + self.right.variables
    }

    override public var derivatives: Set<Derivative> {
        return self.left.derivatives + self.right.derivatives
    }

    override public var typeIdentifier: String {
        var hasher = Hasher()
        self.hash(into: &hasher)
        return "assign\(hasher.finalize())"
    }
    
    required public init(_ params: [Node]) {
        self.left = params[0]
        self.right = params[1]
    }

    override required public init() {
        self.left = Node()
        self.right = Node()
        super.init()
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }

    override public func getSymbol<Engine:SymbolicMathEngine>(using: Engine.Type) -> Engine.Symbol? {
        return nil
    }
    
    @inlinable
    override public func evaluate(withValues values: [Node : Double]) throws -> Double {
        throw SymbolLabError.notApplicable(message: "evaluate isn't applicable to assignment")
    }

    override internal func equals(_ otherNode: Node) -> Bool {
        if let eq = otherNode as? Assign {
            return self.left.equals(eq.left) && self.right.equals(eq.right)
        } else {
            return false
        }
    }

    override public func contains<T: Node>(nodeType: T.Type) -> [Id] {
        var ids: [Id] = []
        if(nodeType == Assign.self) {
            ids.append(self.id)
        }
        ids.append(contentsOf: self.left.contains(nodeType: nodeType))
        ids.append(contentsOf: self.right.contains(nodeType: nodeType))
        return ids
    }

    public override func simplify() -> Node {
        return Assign(self.left.simplify(), self.right.simplify())
    }

    override public func hash(into hasher: inout Hasher) {
        hasher.combine("assign")
        hasher.combine(self.left)
        hasher.combine(self.right)
    }
}

/// A negative number
public class Negative: Node, Operation {
    public let precedence: OperationPrecedence = OperationPrecedence(higherThan: Multiply().precedence)
    public let type: OperationType = .prefix
    public let associativity: OperationAssociativity = .none
    public let identifier: String = "-"
    
    // Store the parameters for the node
    public var argument: Node
    
    override public var description: String {
        return "-\(self.argument)"
    }
    
    override public var latex: String {
        return "-\(self.argument.latex)"
    }
    
    override public var variables: Set<Variable> {
        return self.argument.variables
    }

    override public var derivatives: Set<Derivative> {
        return self.argument.derivatives
    }

    override public var typeIdentifier: String {
        var hasher = Hasher()
        self.hash(into: &hasher)
        return "negative\(hasher.finalize())"
    }
    
    required public init(_ params: [Node]) {
        self.argument = params[0]
    }

    override required public init() {
        self.argument = Node()
        super.init()
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }

    override public func getSymbol<Engine:SymbolicMathEngine>(using type: Engine.Type) -> Engine.Symbol? {
        guard let argumentSymbol = self.argument.getSymbol(using: type) else {
            return nil
        }
        return Engine.negate(argumentSymbol)
    }
    
    @inlinable
    override public func evaluate(withValues values: [Node : Double]) throws -> Double {
        return try -1*self.argument.evaluate(withValues: values)
    }

    override internal func equals(_ otherNode: Node) -> Bool {
        if let neg = otherNode as? Negative {
            return self.argument.equals(neg.argument)
        } else {
            return false
        }
    }

    override public func contains<T: Node>(nodeType: T.Type) -> [Id] {
        var ids: [Id] = []
        if(nodeType == Negative.self) {
            ids.append(self.id)
        }
        ids.append(contentsOf: self.argument.contains(nodeType: nodeType))
        return ids
    }

    public override func simplify() -> Node {
        return Multiply(Number(-1), self.argument.simplify())
    }

    override public func hash(into hasher: inout Hasher) {
        hasher.combine("negative")
        hasher.combine(self.argument)
    }
}

/// Add one node to the other.
public class Add: Node, Operation {
    
    public let precedence: OperationPrecedence = OperationPrecedence(higherThan: Assign().precedence)
    public let type: OperationType = .infix
    public let associativity: OperationAssociativity = .left
    public let identifier: String = "+"
    
    // Store the parameters for the node
    public var arguments: [Node]
    
    override public var description: String {
        var str = ""

        for i in 0..<self.arguments.count-1 {
            if let op = self.arguments[i] as? Operation {
                if(op.precedence <= self.precedence && op.type == .infix) {
                    str += "(\(op))"
                } else {
                    str += "\(op)"
                }
            } else {
                str += self.arguments[i].description
            }
            str += "+"
        }
        
        if let op = self.arguments[self.arguments.count-1] as? Operation {
            if(op.precedence <= self.precedence && op.type == .infix) {
                str += "(\(op))"
            } else {
                str += "\(op)"
            }
        } else {
            str += self.arguments[self.arguments.count-1].description
        }
        
        return str
    }
    
    override public var latex: String {
        return self.description
    }
    
    override public var variables: Set<Variable> {
        var variables: Set<Variable> = []
        
        for arg in self.arguments {
            variables = variables + arg.variables
        }

        return variables
    }

    override public var derivatives: Set<Derivative> {
        var derivatives: Set<Derivative> = []
        
        for arg in self.arguments {
            derivatives = derivatives + arg.derivatives
        }

        return derivatives
    }

    override public var typeIdentifier: String {
        var hasher = Hasher()
        self.hash(into: &hasher)
        return "addition\(hasher.finalize())"
    }
    
    required public init(_ params: [Node]) {
        self.arguments = params
    }

    override required public init() {
        self.arguments = []
        super.init()
    }

    public convenience init(_ params: Node...) {
        self.init(params)
    }

    override public func getSymbol<Engine:SymbolicMathEngine>(using backend: Engine.Type) -> Engine.Symbol? {
        var symbols: [Engine.Symbol] = []
        for arg in self.arguments {
            if let symbol = arg.getSymbol(using: backend) {
                symbols.append(symbol)
            } else {
                return nil
            }
        }
        return Engine.add(symbols)
    }
    
    @inlinable
    override public func evaluate(withValues values: [Node : Double]) throws -> Double {
        var sum: Double = 0
        for arg in self.arguments {
            sum = try sum + arg.evaluate(withValues: values)
        }
        return sum
    }

    override internal func equals(_ otherNode: Node) -> Bool {
        if let add = otherNode as? Add {
            if(self.arguments.count == add.arguments.count) {
                var isEqual = true
                for i in 0..<self.arguments.count {
                    isEqual = isEqual && (self.arguments[i].equals(add.arguments[i]))
                }
                return isEqual
            } else {
                return false
            }
        } else {
            return false
        }
    }

    override public func contains<T: Node>(nodeType: T.Type) -> [Id] {
        var ids: [Id] = []
        if(nodeType == Add.self) {
            ids.append(self.id)
        }
        for arg in self.arguments {
            ids.append(contentsOf: arg.contains(nodeType: nodeType))
        }

        return ids
    }

    public override func simplify() -> Node {

        func level(_  node: Add) -> Add {
            // Leveling of any addition operators to one operator
            var leveled: [Node] = []
            for term in node.arguments {
                if let add = term as? Add {
                    leveled.append(contentsOf: add.arguments)
                } else {
                    leveled.append(term)
                }
            }
            return Add(leveled)
        }

        func combineNumbers(_ node: Add) -> Add {
            // Combine numbers
            var numbers: [Number] = []
            var other: [Node] = []
            for term in node.arguments {
                if let num = term as? Number {
                    numbers.append(num)
                } else {
                    other.append(term)
                }
            }
            // Add all the numbers found
            if(numbers.count > 1) {
                var sum: Double = 0
                for num in numbers {
                    sum += num.value
                }
                other.append(Number(sum))
            } else if(numbers.count == 1) {
                other.append(contentsOf: numbers)
            }
            return Add(other)
        }

        func combineLike(_ node: Add) -> Add {
            var args = node.arguments
            var reducedTerms: [Node] = []
            var i = 0
            while(i < args.count) {
                var current = args[i]
                var multiple: Node = Number(1)
                if let mul = current as? Multiply {
                    current = mul.arguments[0]
                    multiple = Multiply(Array<Node>(mul.arguments[1..<mul.arguments.count])).simplify()
                }
                var j = i + 1
                while(j < args.count) {
                    if(args[j] == current) {
                        multiple = Add(multiple, Number(1))
                        args.remove(at: args.startIndex + j)
                        j -= 1
                    } else if let mul = args[j] as? Multiply {
                        if(current == mul.arguments[0]) {
                            multiple = Add(multiple, Multiply(Array<Node>(mul.arguments[1..<mul.arguments.count])).simplify())
                            args.remove(at: args.startIndex + j)
                            j -= 1
                        }
                    }
                    j += 1
                }

                reducedTerms.append(Multiply(current, multiple).simplify())
                i += 1
            }

            return Add(reducedTerms)
        }

        func sortNodes(_ node: Add) -> Add {
            return Add(node.arguments.sorted())
        }

        func removeZero(_ node: Add) -> Add {
            var args = node.arguments
            args.removeAll(where: {$0 == Number(0)})
            return Add(args)
        }

        func terminal(_ node: Add) -> Node {
            if(node.arguments.count == 1) {
                return node.arguments[0]
            } else if(node.arguments.count == 0) {
                return Number(0)
            } else {
                return node
            }
        }

        var args = self.arguments.map({$0.simplify()})
        var simplifiedAdd = Add(args)

        simplifiedAdd = level(simplifiedAdd)
        simplifiedAdd = combineNumbers(simplifiedAdd)
        simplifiedAdd = combineLike(simplifiedAdd)
        simplifiedAdd = sortNodes(simplifiedAdd)
        simplifiedAdd = removeZero(simplifiedAdd)

        return terminal(simplifiedAdd)
    }

    override public func hash(into hasher: inout Hasher) {
        hasher.combine("add")
        hasher.combine(self.arguments)
    }
}

/// Subtract one node from the other.
public class Subtract: Node, Operation {
    
    public let precedence: OperationPrecedence = OperationPrecedence(higherThan: Assign().precedence)
    public let type: OperationType = .infix
    public let associativity: OperationAssociativity = .left
    public let identifier: String = "-"
    
    // Store the parameters for the node
    public var left: Node
    public var right: Node
    
    override public var description: String {
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
                rightString = "(\(rightString))"
            }
        }
        
        return "\(leftString)-\(rightString)"
    }
    
    override public var latex: String {
        return self.description
    }
    
    override public var variables: Set<Variable> {
        return self.left.variables + self.right.variables
    }

    override public var derivatives: Set<Derivative> {
        return self.left.derivatives + self.right.derivatives
    }

    override public var typeIdentifier: String {
        var hasher = Hasher()
        self.hash(into: &hasher)
        return "subtraction\(hasher.finalize())"
    }
    
    required public init(_ params: [Node]) {
        self.left = params[0]
        self.right = params[1]
    }

    override required public init() {
        self.left = Node()
        self.right = Node()
        super.init()
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }

    override public func getSymbol<Engine:SymbolicMathEngine>(using type: Engine.Type) -> Engine.Symbol? {
        guard let left = self.left.getSymbol(using: type) else {return nil}
        guard let right = self.right.getSymbol(using: type) else {return nil}
        return Engine.subtract(left, right)
    }
    
    @inlinable
    override public func evaluate(withValues values: [Node: Double]) throws -> Double {
        return try self.left.evaluate(withValues: values) - self.right.evaluate(withValues: values)
    }

    override internal func equals(_ otherNode: Node) -> Bool {
        if let sub = otherNode as? Subtract {
            return self.left.equals(sub.left) && self.right.equals(sub.right)
        } else {
            return false
        }
    }

    override public func contains<T: Node>(nodeType: T.Type) -> [Id] {
        var ids: [Id] = []
        if(nodeType == Subtract.self) {
            ids.append(self.id)
        }
        ids.append(contentsOf: self.left.contains(nodeType: nodeType))
        ids.append(contentsOf: self.right.contains(nodeType: nodeType))
        return ids
    }

    public override func simplify() -> Node {
        let leftSimplified = self.left.simplify()
        let rightSimplified = self.right.simplify()

        // Test if both are numbers
        let leftIsNum = leftSimplified as? Number != nil
        let rightIsNum = rightSimplified as? Number != nil

        if(leftIsNum && rightIsNum) {
            return Number((leftSimplified as! Number).value - (rightSimplified as! Number).value)
        }
        
        return Add(leftSimplified, Multiply(Number(-1), rightSimplified).simplify()).simplify()
    }

    override public func hash(into hasher: inout Hasher) {
        hasher.combine("subtract")
        hasher.combine(self.left)
        hasher.combine(self.right)
    }
}

/// Multiply one node by the other.
public class Multiply: Node, Operation {
    
    public let precedence: OperationPrecedence = OperationPrecedence(higherThan: Add().precedence)
    public let type: OperationType = .infix
    public let associativity: OperationAssociativity = .left
    public let identifier: String = "*"
    
    // Store the parameters for the node
    public var arguments: [Node]
    
    override public var description: String {
        var str = ""

        for i in 0..<self.arguments.count-1 {
            if let op = self.arguments[i] as? Operation {
                if(op.precedence <= self.precedence && op.type == .infix) {
                    str += "(\(op))"
                } else {
                    str += "\(op)"
                }
            } else {
                str += self.arguments[i].description
            }
            str += "*"
        }
        
        if let op = self.arguments[self.arguments.count-1] as? Operation {
            if(op.precedence <= self.precedence && op.type == .infix) {
                str += "(\(op))"
            } else {
                str += "\(op)"
            }
        } else {
            str += self.arguments[self.arguments.count-1].description
        }
        
        return str
    }
    
    override public var latex: String {
        return self.description
    }
    
    override public var variables: Set<Variable> {
        var variables: Set<Variable> = []
        
        for arg in self.arguments {
            variables = variables + arg.variables
        }

        return variables
    }

    override public var derivatives: Set<Derivative> {
        var derivatives: Set<Derivative> = []
        
        for arg in self.arguments {
            derivatives = derivatives + arg.derivatives
        }

        return derivatives
    }

    override public var typeIdentifier: String {
        var hasher = Hasher()
        self.hash(into: &hasher)
        return "multiplication\(hasher.finalize())"
    }
    
    required public init(_ params: [Node]) {
        self.arguments = params
    }

    override required public init() {
        self.arguments = []
        super.init()
    }

    public convenience init(_ params: Node...) {
        self.init(params)
    }

    override public func getSymbol<Engine:SymbolicMathEngine>(using type: Engine.Type) -> Engine.Symbol? {
        var terms: [Engine.Symbol] = []
        for term in self.arguments {
            if let termn = term.getSymbol(using: type) {
                terms.append(termn)
            } else {
                return nil
            }
        }
        return Engine.multiply(terms)
    }
    
    @inlinable
    override public func evaluate(withValues values: [Node: Double]) throws -> Double {
        var current: Double = 1
        for arg in self.arguments {
            current *= try arg.evaluate(withValues: values)
        }
        return current
    }

    override internal func equals(_ otherNode: Node) -> Bool {
        if let mul = otherNode as? Multiply {
            if(self.arguments.count == mul.arguments.count) {
                var isEqual = true
                for i in 0..<self.arguments.count {
                    isEqual = isEqual && (self.arguments[i].equals(mul.arguments[i]))
                }
                return isEqual
            } else {
                return false
            }
        } else {
            return false
        }
    }

    override public func contains<T: Node>(nodeType: T.Type) -> [Id] {
        var ids: [Id] = []
        if(nodeType == Multiply.self) {
            ids.append(self.id)
        }
        for arg in self.arguments {
            ids.append(contentsOf: arg.contains(nodeType: nodeType))
        }

        return ids
    }

    public override func simplify() -> Node {

        func level(_ node: Multiply) -> Multiply {
            // Level the operator to only one level of multipliation
            var leveled: [Node] = []
            for term in node.arguments {
                if let mul = term as? Multiply {
                    leveled.append(contentsOf: mul.arguments)
                } else {
                    leveled.append(term)
                }
            }
            return Multiply(leveled)
        }

        func combineNumbers(_ node: Multiply) -> Multiply {
            // combine all numbers
            var numbers: [Number] = []
            var other: [Node] = []
            for term in node.arguments {
                if let num = term as? Number {
                    numbers.append(num)
                } else {
                    other.append(term)
                }
            }
            if(numbers.count > 1) {
                var sum: Double = 1
                for num in numbers {
                    sum *= num.value
                }
                other.append(Number(sum))
            } else if(numbers.count == 1) {
                other.append(contentsOf: numbers)
            }
            return Multiply(other)
        }

        func fractionProduct(_ node: Multiply) -> Node {
            // We want (a/b)*(c/d) --> (a*c)/(b*d)
            var tops: [Node] = []
            var bottoms: [Node] = []
            for term in node.arguments {
                if let div = term as? Divide {
                    tops.append(div.left)
                    bottoms.append(div.right)
                } else {
                    tops.append(term)
                }
            }

            tops.sort()
            bottoms.sort()

            // We call simplify again because not everything may be level anymore
            if(bottoms.count == 0) {
                if(tops.count == 1) {
                    return tops[0]
                } else {
                    return Multiply(tops)
                }
            } else if(bottoms.count == 1) {
                if(tops.count == 1) {
                    return Divide(tops[0], bottoms[0]).simplify()
                } else {
                    return Divide(Multiply(tops).simplify(), bottoms[0]).simplify()
                }
            } else {
                if(tops.count == 1) {
                    return Divide(tops[0], Multiply(bottoms).simplify()).simplify()
                } else {
                    return Divide(Multiply(tops).simplify(), Multiply(bottoms).simplify()).simplify()
                }
            }
        }

        func combineLike(_ node: Multiply) -> Multiply {
            var args = node.arguments
            var reducedTerms: [Node] = []
            var i = 0
            while(i < args.count) {
                var current = args[i]
                var exponent: Node = Number(1)
                if let pow = current as? Power {
                    current = pow.left
                    exponent = pow.right
                }
                var j = i + 1
                while(j < args.count) {
                    if(args[j] == current) {
                        exponent = Add(exponent, Number(1))
                        args.remove(at: args.startIndex + j)
                        j -= 1
                    } else if let pow = args[j] as? Power {
                        if(pow.left == current) {
                            exponent = Add(exponent, pow.right)
                            args.remove(at: args.startIndex + j)
                            j -= 1
                        }
                    }
                    j += 1
                }

                reducedTerms.append(Power(current, exponent).simplify())
                i += 1
            }

            return Multiply(reducedTerms)
        }

        func removeOne(_ node: Multiply) -> Multiply {
            var args = node.arguments
            args.removeAll(where: {$0 == Number(1)})
            return Multiply(args)
        }

        var args = self.arguments.map({$0.simplify()})

        var simplifiedMul = Multiply(args)
        simplifiedMul = level(simplifiedMul)
        simplifiedMul = combineNumbers(simplifiedMul)
        simplifiedMul = combineLike(simplifiedMul)
        simplifiedMul = removeOne(simplifiedMul)

        // Idk why, but combineLike seems to put multiples nested.
        // TODO: Figure out why, something in combineLike. Look at second test in testDerivativeCos
        // for an example of an issue.
        simplifiedMul = level(simplifiedMul)
        simplifiedMul = combineNumbers(simplifiedMul)

        if(simplifiedMul.arguments.contains(Number(0))) {
            return Number(0)
        } else if(simplifiedMul.arguments.count == 1) {
            return simplifiedMul.arguments[0]
        } else if(simplifiedMul.arguments.count == 0) {
            return Number(1)
        }

        return fractionProduct(simplifiedMul)
    }

    override public func hash(into hasher: inout Hasher) {
        hasher.combine("multiply")
        hasher.combine(self.arguments)
    }
}

/// Divide one node by the other.
public class Divide: Node, Operation {
    
    public let precedence: OperationPrecedence = OperationPrecedence(higherThan: Add().precedence)
    public let type: OperationType = .infix
    public let associativity: OperationAssociativity = .left
    public let identifier: String = "/"
    
    // Store the parameters for the node
    public var left: Node
    public var right: Node
    
    override public var description: String {
        var leftString = "\(self.left)"
        var rightString = "\(self.right)"
        
        // Wrap the sides if needed
        if let op = self.left as? Operation {
            if(op.precedence <= self.precedence && op.type == .infix) {
                leftString = "(\(leftString))"
            }
        }
        if let op = self.right as? Operation {
            if(op.precedence <= self.precedence && op.type == .infix) {
                rightString = "(\(rightString))"
            }
        }
        
        return "\(leftString)/\(rightString)"
    }
    
    override public var latex: String {
        return "\\frac{\(self.left.latex)}{\(self.right.latex)}"
    }
    
    override public var variables: Set<Variable> {
        return self.left.variables + self.right.variables
    }

    override public var derivatives: Set<Derivative> {
        return self.left.derivatives + self.right.derivatives
    }

    override public var typeIdentifier: String {
        var hasher = Hasher()
        self.hash(into: &hasher)
        return "division\(hasher.finalize())"
    }
    
    required public init(_ params: [Node]) {
        self.left = params[0]
        self.right = params[1]
    }

    public init(_ left: Node, _ right: Node) {
        self.left = left
        self.right = right
    }

    override required public init() {
        self.left = Node()
        self.right = Node()
        super.init()
    }

    override public func getSymbol<Engine:SymbolicMathEngine>(using type: Engine.Type) -> Engine.Symbol? {
        guard let left = self.left.getSymbol(using: type) else {return nil}
        guard let right = self.right.getSymbol(using: type) else {return nil}
        return Engine.divide(left, right)
    }
    
    @inlinable
    override public func evaluate(withValues values: [Node: Double]) throws -> Double {
        return try self.left.evaluate(withValues: values) / self.right.evaluate(withValues: values)
    }

    override internal func equals(_ otherNode: Node) -> Bool {
        if let div = otherNode as? Divide {
            return self.left.equals(div.left) && self.right.equals(div.right)
        } else {
            return false
        }
    }

    override public func contains<T: Node>(nodeType: T.Type) -> [Id] {
        var ids: [Id] = []
        if(nodeType == Divide.self) {
            ids.append(self.id)
        }
        ids.append(contentsOf: self.left.contains(nodeType: nodeType))
        ids.append(contentsOf: self.right.contains(nodeType: nodeType))
        return ids
    }
    
    public override func simplify() -> Node {
        func toMulPowers(_ node: Node) -> Multiply {
            switch node {
            case let mul as Multiply:
                return Multiply(mul.arguments.map({
                    if let pow = $0 as? Power {
                        return pow
                    } else {
                        return Power($0, Number(1))
                    }
                }))
            case let pow as Power:
                return Multiply(pow, Power(Number(1), Number(1)))
            default:
                return Multiply(Power(node, Number(1)), Power(Number(1), Number(1)))
            }
        }

        func cancelTerms(_ node: Divide) -> Node {
            var leftTerms: [Power] = toMulPowers(node.left).arguments as! [Power]
            var rightTerms: [Power] = toMulPowers(node.right).arguments as! [Power]

            for i in 0..<leftTerms.count {
                for j in 0..<rightTerms.count {
                    // Check the bases are the same
                    if(leftTerms[i].left == rightTerms[j].left) {
                        if(leftTerms[i].right > rightTerms[j].right) {
                            leftTerms[i] = Power(leftTerms[i].left, Subtract(leftTerms[i].right, rightTerms[j].right))
                            rightTerms[j] = Power(Number(1), Number(1))
                        } else if(leftTerms[i].right < rightTerms[j].right) {
                            rightTerms[j] = Power(rightTerms[j].left, Subtract(rightTerms[j].right, leftTerms[i].right))
                            leftTerms[i] = Power(Number(1), Number(1))
                        } else {
                            rightTerms[j] = Power(Number(1), Number(1))
                            leftTerms[i] = Power(Number(1), Number(1))
                        }
                    }
                }
            }

            let leftSimplified = Multiply(leftTerms).simplify()
            let rightSimplified = Multiply(rightTerms).simplify()

            if(rightSimplified == Number(1)) {
                return leftSimplified
            } else {
                return Divide(leftSimplified, rightSimplified)
            }
        }

        let leftSimplified = self.left.simplify()
        let rightSimplified = self.right.simplify()

        let leftIsNum = leftSimplified as? Number != nil
        let rightIsNum = rightSimplified as? Number != nil

        // Combine numbers into one
        if(leftIsNum && rightIsNum) {
            return Number((leftSimplified as! Number).value / (rightSimplified as! Number).value)
        }

        let leftIsDiv = leftSimplified as? Divide != nil
        let rightIsDiv = rightSimplified as? Divide != nil

        if(leftIsDiv && rightIsDiv) {
            // We want (a/b)/(c/d) --> (a*d)/(b*c)
            let leftDiv = leftSimplified as! Divide
            let rightDiv = rightSimplified as! Divide
            return Divide(leftDiv.left * rightDiv.right, leftDiv.right * rightDiv.left).simplify()
        } else if(leftIsDiv && !rightIsDiv) {
            // We want to simplify (a/b)/c --> a/(b*c)
            let leftDiv = leftSimplified as! Divide
            return Divide(leftDiv.left, leftDiv.right * rightSimplified).simplify()
        } else if(!leftIsDiv && rightIsDiv) {
            // We want a/(b/c) --> (a*c)/b
            let rightDiv = rightSimplified as! Divide
            return Divide(leftSimplified*rightDiv.right, rightDiv.left).simplify()
        } else {
            // Default case
            if(rightSimplified == Number(1)) {
                return leftSimplified
            } else {
                var simplifiedDiv: Divide = Divide(leftSimplified, rightSimplified)
                return cancelTerms(simplifiedDiv)
            }
        }
    }

    override public func hash(into hasher: inout Hasher) {
        hasher.combine("divide")
        hasher.combine(self.left)
        hasher.combine(self.right)
    }
}

/// Power of one node to the other.
public class Power: Node, Operation {
    
    public let precedence: OperationPrecedence = OperationPrecedence(higherThan: Negative().precedence)
    public let type: OperationType = .infix
    public let associativity: OperationAssociativity = .right
    public let identifier: String = "^"
    
    // Store the parameters for the node
    public var left: Node
    public var right: Node
    
    override public var description: String {
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
                rightString = "(\(rightString))"
            }
        }
        
        return "\(leftString)^\(rightString)"
    }
    
    override public var latex: String {
        var leftString = self.left.latex
        if let op = self.left as? Operation {
            if(op.precedence < self.precedence && op.type == .infix) {
                leftString = "(\(leftString))"
            }
        }
        return "\(leftString)^{\(self.right.latex)}"
    }
    
    override public var variables: Set<Variable> {
        return self.left.variables + self.right.variables
    }

    override public var derivatives: Set<Derivative> {
        return self.left.derivatives + self.right.derivatives
    }

    override public var typeIdentifier: String {
        var hasher = Hasher()
        self.hash(into: &hasher)
        return "power\(hasher.finalize())"
    }
    
    required public init(_ params: [Node]) {
        self.left = params[0]
        self.right = params[1]
    }

    public init(_ left: Node, _ right: Node) {
        self.left = left
        self.right = right
    }

    override required public init() {
        self.left = Node()
        self.right = Node()
        super.init()
    }

    override public func getSymbol<Engine:SymbolicMathEngine>(using type: Engine.Type) -> Engine.Symbol? {
        guard let left = self.left.getSymbol(using: type) else {return nil}
        guard let right = self.right.getSymbol(using: type) else {return nil}
        return Engine.exponentiate(left, right)
    }
    
    @inlinable
    override public func evaluate(withValues values: [Node: Double]) throws -> Double {
        return try Double.pow(self.left.evaluate(withValues: values), self.right.evaluate(withValues: values))
    }

    override internal func equals(_ otherNode: Node) -> Bool {
        if let power = otherNode as? Power {
            return self.left.equals(power.left) && self.right.equals(power.right)
        } else {
            return false
        }
    }

    override public func contains<T: Node>(nodeType: T.Type) -> [Id] {
        var ids: [Id] = []
        if(nodeType == Power.self) {
            ids.append(self.id)
        }
        ids.append(contentsOf: self.left.contains(nodeType: nodeType))
        ids.append(contentsOf: self.right.contains(nodeType: nodeType))
        return ids
    }

    public override func simplify() -> Node {
        let leftSimplified = self.left.simplify()
        let rightSimplified = self.right.simplify()

        let leftIsNum = leftSimplified as? Number != nil
        let rightIsNum = rightSimplified as? Number != nil

        if(rightIsNum && (rightSimplified as! Number) == Number(1)) {
            return leftSimplified
        } else if(rightIsNum && (rightSimplified as! Number) == Number(0)) {
            return Number(1)
        } else if(leftIsNum && rightIsNum) {
            return Number(Double.pow((leftSimplified as! Number).value, (rightSimplified as! Number).value))
        }

        return Power(leftSimplified, rightSimplified)
    }

    override public func hash(into hasher: inout Hasher) {
        hasher.combine("power")
        hasher.combine(self.left)
        hasher.combine(self.right)
    }
}

/// Factorial of a node.
public class Factorial: Node, Operation {
    
    public let precedence: OperationPrecedence = OperationPrecedence(higherThan: Power().precedence)
    public let type: OperationType = .postfix
    public let associativity: OperationAssociativity = .none
    public let identifier: String = "!"
    
    // Store the parameters for the node
    private var argument: Node
    
    override public var description: String {
        // Wrap if needed
        if let op = self.argument as? Operation {
            if(op.type != .function) {
                return "(\(self.argument))!"
            }
        }
        
        return "\(self.argument)!"
    }
    
    override public var latex: String {
        // Wrap if needed
        if let op = self.argument as? Operation {
            if(op.type != .function) {
                return "(\(self.argument.latex))!"
            }
        }
        
        return "\(self.argument.latex)!"
    }
    
    override public var variables: Set<Variable> {
        return self.argument.variables
    }

    override public var derivatives: Set<Derivative> {
        return self.argument.derivatives
    }

    override public var typeIdentifier: String {
        var hasher = Hasher()
        self.hash(into: &hasher)
        return "factorial\(hasher.finalize())"
    }
    
    required public init(_ params: [Node]) {
        self.argument = params[0]
    }

    public init(_ param: Node) {
        self.argument = param
    }

    override required public init() {
        self.argument = Node()
        super.init()
    }

    override public func getSymbol<Engine:SymbolicMathEngine>(using type: Engine.Type) -> Engine.Symbol? {
        // TODO: Define the general factorial
        return nil
    }
    
    @inlinable
    override public func evaluate(withValues values: [Node: Double]) throws -> Double {
        // TODO: Factorial evaluation
        throw SymbolLabError.notApplicable(message: "Factorial not implemented for the moment")
    }

    override internal func equals(_ otherNode: Node) -> Bool {
        if let fact = otherNode as? Factorial {
            return self.argument.equals(fact.argument)
        } else {
            return false
        }
    }

    override public func contains<T: Node>(nodeType: T.Type) -> [Id] {
        var ids: [Id] = []
        if(nodeType == Factorial.self) {
            ids.append(self.id)
        }
        ids.append(contentsOf: self.argument.contains(nodeType: nodeType))
        return ids
    }

    public override func simplify() -> Node {
        return Factorial(self.argument.simplify())
    }

    override public func hash(into hasher: inout Hasher) {
        hasher.combine("factorial")
        hasher.combine(self.argument)
    }
}

