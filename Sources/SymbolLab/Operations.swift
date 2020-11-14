//
//  File.swift
//  
//
//  Created by Ian Ruh on 5/14/20.
//

import Foundation

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
    
    func factory(_ params: [Node]) -> Node
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
    
    override public var variables: Set<String> {
        return self.left.variables + self.right.variables
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
    override public func evaluate(withValues values: [String : Double]) throws -> Double {
        throw SymbolLabError.notApplicable(message: "evaluate isn't applicable to assignment")
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

    public override func replace(id: Id, with replacement: Node) throws -> Bool {
        guard id != self.id else {
            throw SymbolLabError.cannotReplaceNode("because cannot replace self.")
        }

        // Replace children
        if(self.right.id == id) {
            self.right = replacement
            return true
        } else if(self.left.id == id) {
            self.left = replacement
            return true
        }

        // Recursively(ish) search children
        return try self.left.replace(id: id, with: replacement) || self.right.replace(id: id, with: replacement)
    }

    public override func getNode(withId id: Id) -> Node? {
        if(self.id == id) {
            return self
        }

        // Try left, then fall bacl to right
        if let node = self.left.getNode(withId: id) {
            return node
        } else {
            return self.right.getNode(withId: id)
        }
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
        // MAYBE?
//        guard self.argument.isBasic || self.argument as? Decimal != nil else {
//            print("Missused negative operation : '-\(self.argument)'")
//            return ""
//        }
        return "-\(self.argument)"
    }
    
    override public var latex: String {
        // MAYBE?
//        guard self.argument.isBasic || self.argument as? Decimal != nil else {
//            print("Missused negative operation : '-\(self.argument)'")
//            return ""
//        }
        return "-\(self.argument.latex)"
    }
    
    override public var variables: Set<String> {
        return self.argument.variables
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
    override public func evaluate(withValues values: [String : Double]) throws -> Double {
        return try -1*self.argument.evaluate(withValues: values)
    }

    override public func contains<T: Node>(nodeType: T.Type) -> [Id] {
        var ids: [Id] = []
        if(nodeType == Negative.self) {
            ids.append(self.id)
        }
        ids.append(contentsOf: self.argument.contains(nodeType: nodeType))
        return ids
    }

    public override func replace(id: Id, with replacement: Node) throws -> Bool {
        guard id != self.id else {
            throw SymbolLabError.cannotReplaceNode("because cannot replace self.")
        }

        // Replace children
        if(self.argument.id == id) {
            self.argument = replacement
            return true
        }

        // Recursively(ish) search children
        return try self.argument.replace(id: id, with: replacement)
    }

    public override func getNode(withId id: Id) -> Node? {
        if(self.id == id) {
            return self
        }

        // Try left, then fall bacl to right
        return self.argument.getNode(withId: id)
    }
}

/// A decimal number. Negatives are unknown here.
public class Decimal: Number, Operation, ExpressibleByFloatLiteral {
    public typealias FloatLiteralType = Double

    public let precedence: OperationPrecedence = OperationPrecedence(higherThan: Negative().precedence)
    public let type: OperationType = .infix
    public let associativity: OperationAssociativity = .none
    public let identifier: String = "."
    
    // Store the parameters for the node
    public var valueDouble: Double
    
    override public var description: String {
        return "\(self.valueDouble)"
    }
    
    override public var latex: String {
        return "\(self.valueDouble)"
    }
    
    override public var variables: Set<String> {
        return []
    }
    
    required public init(_ params: [Node]) {
        guard let leftNumber = params[0] as? Number else {
            preconditionFailure("Misused decimal. \(params[0]) is not a Number")
        }
        guard let rightNumber = params[1] as? Number else {
            preconditionFailure("Misused decimal. \(params[1]) is not a Number")
        }
        guard let value = Double("\(leftNumber).\(rightNumber)") else {
            preconditionFailure("Well not idea how this happens. But here you go: \(leftNumber).\(rightNumber) apparently can't be a Double")
        }
        self.valueDouble = value
        super.init(0)
    }

    public required init(floatLiteral value: Double) {
        self.valueDouble = value
        super.init(0)
    }

    required public convenience init(integerLiteral value: Int) {
        self.init(floatLiteral: Double(value))
    }

    public required init() {
        self.valueDouble = 0
        super.init(0)
    }

    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }

    override public func getSymbol<Engine:SymbolicMathEngine>(using: Engine.Type) -> Engine.Symbol? {
        Engine.new(self.valueDouble)
    }
    
    @inlinable
    override public func evaluate(withValues values: [String : Double]) throws -> Double {
        return self.valueDouble
    }

    override public func contains<T: Node>(nodeType: T.Type) -> [Id] {
        var ids: [Id] = []
        if(nodeType == Decimal.self) {
            ids.append(self.id)
        }
        return ids
    }

    public override func replace(id: Id, with replacement: Node) throws -> Bool {
        guard id != self.id else {
            throw SymbolLabError.cannotReplaceNode("because cannot replace self.")
        }

        // No children to replace.
        return false
    }

    public override func getNode(withId id: Id) -> Node? {
        if(self.id == id) {
            return self
        }
        return nil
    }
}

/// Add one node to the other.
public class Add: Node, Operation {
    
    public let precedence: OperationPrecedence = OperationPrecedence(higherThan: Assign().precedence)
    public let type: OperationType = .infix
    public let associativity: OperationAssociativity = .left
    public let identifier: String = "+"
    
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
        
        return "\(leftString)+\(rightString)"
    }
    
    override public var latex: String {
        var leftString = "\(self.left.latex)"
        var rightString = "\(self.right.latex)"
        
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
        
        return "\(leftString)+\(rightString)"
    }
    
    override public var variables: Set<String> {
        return self.left.variables + self.right.variables
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
        return Engine.add(left, right)
    }
    
    @inlinable
    override public func evaluate(withValues values: [String : Double]) throws -> Double {
        return try self.left.evaluate(withValues: values) + self.right.evaluate(withValues: values)
    }

    override public func contains<T: Node>(nodeType: T.Type) -> [Id] {
        var ids: [Id] = []
        if(nodeType == Add.self) {
            ids.append(self.id)
        }
        ids.append(contentsOf: self.left.contains(nodeType: nodeType))
        ids.append(contentsOf: self.right.contains(nodeType: nodeType))
        return ids
    }

    public override func replace(id: Id, with replacement: Node) throws -> Bool {
        guard id != self.id else {
            throw SymbolLabError.cannotReplaceNode("because cannot replace self.")
        }

        // Replace children
        if(self.right.id == id) {
            self.right = replacement
            return true
        } else if(self.left.id == id) {
            self.left = replacement
            return true
        }

        // Recursively(ish) search children
        return try self.left.replace(id: id, with: replacement) || self.right.replace(id: id, with: replacement)
    }

    public override func getNode(withId id: Id) -> Node? {
        if(self.id == id) {
            return self
        }

        // Try left, then fall bacl to right
        if let node = self.left.getNode(withId: id) {
            return node
        } else {
            return self.right.getNode(withId: id)
        }
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
        var leftString = "\(self.left.latex)"
        var rightString = "\(self.right.latex)"
        
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
        
        return "\(leftString)-\(rightString)"
    }
    
    override public var variables: Set<String> {
        return self.left.variables + self.right.variables
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
    override public func evaluate(withValues values: [String : Double]) throws -> Double {
        return try self.left.evaluate(withValues: values) - self.right.evaluate(withValues: values)
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

    public override func replace(id: Id, with replacement: Node) throws -> Bool {
        guard id != self.id else {
            throw SymbolLabError.cannotReplaceNode("because cannot replace self.")
        }

        // Replace children
        if(self.right.id == id) {
            self.right = replacement
            return true
        } else if(self.left.id == id) {
            self.left = replacement
            return true
        }

        // Recursively(ish) search children
        return try self.left.replace(id: id, with: replacement) || self.right.replace(id: id, with: replacement)
    }

    public override func getNode(withId id: Id) -> Node? {
        if(self.id == id) {
            return self
        }

        // Try left, then fall bacl to right
        if let node = self.left.getNode(withId: id) {
            return node
        } else {
            return self.right.getNode(withId: id)
        }
    }
}

/// Multiply one node by the other.
public class Multiply: Node, Operation {
    
    public let precedence: OperationPrecedence = OperationPrecedence(higherThan: Add().precedence)
    public let type: OperationType = .infix
    public let associativity: OperationAssociativity = .left
    public let identifier: String = "*"
    
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
        
        return "\(leftString)*\(rightString)"
    }
    
    override public var latex: String {
        var leftString = "\(self.left.latex)"
        var rightString = "\(self.right.latex)"
        
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
        
        return "\(leftString)\\cdot \(rightString)"
    }
    
    override public var variables: Set<String> {
        return self.left.variables + self.right.variables
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
        return Engine.multiply(left, right)
    }
    
    @inlinable
    override public func evaluate(withValues values: [String : Double]) throws -> Double {
        return try self.left.evaluate(withValues: values) * self.right.evaluate(withValues: values)
    }

    override public func contains<T: Node>(nodeType: T.Type) -> [Id] {
        var ids: [Id] = []
        if(nodeType == Multiply.self) {
            ids.append(self.id)
        }
        ids.append(contentsOf: self.left.contains(nodeType: nodeType))
        ids.append(contentsOf: self.right.contains(nodeType: nodeType))
        return ids
    }

    public override func replace(id: Id, with replacement: Node) throws -> Bool {
        guard id != self.id else {
            throw SymbolLabError.cannotReplaceNode("because cannot replace self.")
        }

        // Replace children
        if(self.right.id == id) {
            self.right = replacement
            return true
        } else if(self.left.id == id) {
            self.left = replacement
            return true
        }

        // Recursively(ish) search children
        return try self.left.replace(id: id, with: replacement) || self.right.replace(id: id, with: replacement)
    }

    public override func getNode(withId id: Id) -> Node? {
        if(self.id == id) {
            return self
        }

        // Try left, then fall bacl to right
        if let node = self.left.getNode(withId: id) {
            return node
        } else {
            return self.right.getNode(withId: id)
        }
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
    
    override public var variables: Set<String> {
        return self.left.variables + self.right.variables
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
        return Engine.divide(left, right)
    }
    
    @inlinable
    override public func evaluate(withValues values: [String : Double]) throws -> Double {
        return try self.left.evaluate(withValues: values) / self.right.evaluate(withValues: values)
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

    public override func replace(id: Id, with replacement: Node) throws -> Bool {
        guard id != self.id else {
            throw SymbolLabError.cannotReplaceNode("because cannot replace self.")
        }

        // Replace children
        if(self.right.id == id) {
            self.right = replacement
            return true
        } else if(self.left.id == id) {
            self.left = replacement
            return true
        }

        // Recursively(ish) search children
        return try self.left.replace(id: id, with: replacement) || self.right.replace(id: id, with: replacement)
    }

    public override func getNode(withId id: Id) -> Node? {
        if(self.id == id) {
            return self
        }

        // Try left, then fall bacl to right
        if let node = self.left.getNode(withId: id) {
            return node
        } else {
            return self.right.getNode(withId: id)
        }
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
    
    override public var variables: Set<String> {
        return self.left.variables + self.right.variables
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
        return Engine.exponentiate(left, right)
    }
    
    @inlinable
    override public func evaluate(withValues values: [String : Double]) throws -> Double {
        return try pow(self.left.evaluate(withValues: values), self.right.evaluate(withValues: values))
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

    public override func replace(id: Id, with replacement: Node) throws -> Bool {
        guard id != self.id else {
            throw SymbolLabError.cannotReplaceNode("because cannot replace self.")
        }

        // Replace children
        if(self.right.id == id) {
            self.right = replacement
            return true
        } else if(self.left.id == id) {
            self.left = replacement
            return true
        }

        // Recursively(ish) search children
        return try self.left.replace(id: id, with: replacement) || self.right.replace(id: id, with: replacement)
    }

    public override func getNode(withId id: Id) -> Node? {
        if(self.id == id) {
            return self
        }

        // Try left, then fall bacl to right
        if let node = self.left.getNode(withId: id) {
            return node
        } else {
            return self.right.getNode(withId: id)
        }
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
    
    override public var variables: Set<String> {
        return self.argument.variables
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
        // TODO: Factorial in symbolic math protocol
        return nil
    }
    
    @inlinable
    override public func evaluate(withValues values: [String : Double]) throws -> Double {
        // TODO: Factorial evaluation
        throw SymbolLabError.notApplicable(message: "Factorial not implemented for the moment")
    }

    override public func contains<T: Node>(nodeType: T.Type) -> [Id] {
        var ids: [Id] = []
        if(nodeType == Factorial.self) {
            ids.append(self.id)
        }
        ids.append(contentsOf: self.argument.contains(nodeType: nodeType))
        return ids
    }

    public override func replace(id: Id, with replacement: Node) throws -> Bool {
        guard id != self.id else {
            throw SymbolLabError.cannotReplaceNode("because cannot replace self.")
        }

        // Replace children
        if(self.argument.id == id) {
            self.argument = replacement
            return true
        }

        // Recursively(ish) search children
        return try self.argument.replace(id: id, with: replacement)
    }

    public override func getNode(withId id: Id) -> Node? {
        if(self.id == id) {
            return self
        }

        // Try left, then fall bacl to right
        return self.argument.getNode(withId: id)
    }
}

