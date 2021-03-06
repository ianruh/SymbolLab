//
//  File.swift
//  
//
//  Created by Ian Ruh on 5/14/20.
//

public class Node: CustomStringConvertible, Comparable, Hashable {

    //------------------------ Properties ------------------------

    /// The node's unqie identifier
    lazy public var id: Id = Id()

    /// A string representation of the node. This should be overridden.
    public var description: String {
        preconditionFailure("description should be overridden")
    }

    /// A latex representation of the node. This should be overridden.
    public var latex: String {
        preconditionFailure("latex should be overridden")
    }

    /// The set of varibales in the node. This should be overridden.
    public var variables: Set<Variable> {
        preconditionFailure("variables should be overridden")
    }

    /// The set of derivatives in the node. This should be overriden.
    public var derivatives: Set<Derivative> {
        preconditionFailure("derivatives should be overridden")
    }

    /// The type identifier of the class. This should be overriden.
    public var typeIdentifier: String {
        preconditionFailure("variables should be overridden")
    }

    /// Determine if the node is basic
    public var isBasic: Bool {
        return self as? Number != nil || self as? Variable != nil
    }

    /// Dertermine if the node is a variable
    public var isVariable: Bool {
        return self as? Variable != nil
    }

    /// Dertermine if the node is a variable
    public var isNumber: Bool {
        return self as? Number != nil
    }

    /// Determine if the node is an operation
    public var isOperation: Bool {
        return self as? Operation != nil
    }

    /// Determine is the node is a function
    public var isFunction: Bool {
        return self as? Function != nil
    }

    /// Determin if the node is and ODE. If so, return a tuple of the independent and dependent variable.
    public var isODE: (dep: Variable, ind: Variable, derId: Id)? {
        let derivatives = Array(self.derivatives)
        if(derivatives.count > 1) {
            guard let dep = derivatives[0].diffOf as? Variable else {return nil}
            guard let ind = derivatives[0].withRespectTo as? Variable else {return nil}
            return (dep: dep, ind: ind, derId: Id())
        }
        return nil
    }

    //------------------------ Functions ------------------------

    public func getSymbol<Engine:SymbolicMathEngine>(using: Engine.Type) -> Engine.Symbol? {
        preconditionFailure("This method must be overridden")
    }

    /// Evaluate the node. This should be overridden.
    public func evaluate(withValues values: [Node: Double]) throws -> Double {
        preconditionFailure("This method must be overridden")
    }

    /// Function returns whether the other node logically equals this function
    /// Note that this assumes both sides are simplified already, so it doesn't
    /// call simplify itself.
    internal func equals(_ otherNode: Node) -> Bool {
        preconditionFailure("This method must be overridden")
    }

    /// Get the count of how many of the given elements are in the node.
    ///
    /// - Parameter nodeType: Type interested in
    /// - Returns: The number found.
    public func contains<T: Node>(nodeType: T.Type) -> [Id] {
        preconditionFailure("This method must be overridden")
    }

    /// Replace the node with the given id with another node.
    ///
    /// - Parameters:
    ///   - id: The ID of the node to be replaced.
    ///   - replacement: The replacement node.
    /// - Returns: Returns true if the node was replaced, and false otherwise.
    /// - Throws: If the node cannot be replaced.
    public func replace(id: Id, with replacement: Node) throws -> Bool {
        preconditionFailure("This method must be overridden")
    }

    /// Replace a node with another node.
    @discardableResult public func replace(_ targetNode: Node, with replacement: Node) -> Node {
        preconditionFailure("This method must be overridden.")
    }

    /// Get the node with the given id.
    ///
    /// - Parameter id: Id of the node to get.
    /// - Returns: The node with the given id, if it exists in the tree.
    public func getNode(withId id: Id) -> Node? {
        preconditionFailure("This method must be overridden")
    }

    /// Simplify the node
    ///
    /// - Returns: The simplified node, or the same node if no simplification has been performed.
    public func simplify() -> Node {
        preconditionFailure("This method must be overridden")
    }

    public func hash(into hasher: inout Hasher) {
        preconditionFailure("This method must be overriden")
    }

    //--------------Comparable Conformance-----------------

    public static func ==(_ lhs: Node, _ rhs: Node) -> Bool {
        return lhs.equals(rhs)
    }

    public static func ~=(_ lhs: Node, _ rhs: Node) -> Bool {
        return lhs.simplify() == rhs.simplify()
    }

    /// Only does a cursory comparison of types. Will be correct for numbers and variables,
    /// nut otherwise only compares the types of the nodes.
    ///
    /// Opertions < Variables < Numbers
    public static func <(_ lhs: Node, _ rhs: Node) -> Bool {
        if(lhs.isOperation && rhs.isOperation) {
            return lhs.typeIdentifier < rhs.typeIdentifier
        } else if(lhs.isOperation &&  rhs.isBasic) {
            return true
        } else if(lhs.isBasic && rhs.isOperation) {
            return false
        } else if(lhs.isVariable && rhs.isVariable) {
            return (lhs as! Variable).string < (rhs as! Variable).string
        } else if(lhs.isVariable && rhs.isNumber) {
            return true
        } else if(lhs.isNumber && rhs.isVariable) {
            return false
        } else if(lhs.isNumber && rhs.isNumber) {
            return (lhs as! Number).value < (rhs as! Number).value
        } else {
            // This shouldn't ever run, but just in case
            preconditionFailure("Less than last case should never run")
            return lhs.typeIdentifier < rhs.typeIdentifier
        }
    }
}

public class Number: Node, ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral {
    public typealias IntegerLiteralType = Int
    public typealias FloatLiteralType = Double
    

    public var value: Double
    
    override public var description: String {
        return "\(self.value)"
    }

    override public var variables: Set<Variable> {
        return []
    }

    override public var derivatives: Set<Derivative> {
        return []
    }

    override public var typeIdentifier: String {
        return "\(self.value)"
    }
    
    override public var latex: String {
        return "\(self.value)"
    }
    
    public convenience init(_ num: Int) {
        self.init(Double(num))
    }

    public init(_ num: Double) {
        self.value = num
    }

    required public convenience init(integerLiteral value: Int) {
        self.init(Double(value))
    }

    required public convenience init(floatLiteral value: Double) {
        self.init(value)
    }

    public override func getSymbol<Engine: SymbolicMathEngine>(using: Engine.Type) -> Engine.Symbol? {
        let t = Engine.new(self.value)
        return t
    }
    
    @inlinable
    override public func evaluate(withValues values: [Node : Double]) throws -> Double {
        return self.value
    }

    override internal func equals(_ otherNode: Node) -> Bool {
        if let num = otherNode as? Number {
            return self.value == num.value
        } else {
            return false
        }
    }

    override public func contains<T: Node>(nodeType: T.Type) -> [Id] {
        if(nodeType == Number.self) {
            return [self.id]
        } else {
            return []
        }
    }

    @discardableResult override public func replace(_ targetNode: Node, with replacement: Node) -> Node {
        if(targetNode == self) {
            return replacement
        } else {
            return self
        }
    }

    override public func simplify() -> Node {
        return self
    }

    override public func hash(into hasher: inout Hasher) {
        hasher.combine("number")
        hasher.combine(self.value)
    }
}

public class Variable: Node, ExpressibleByStringLiteral {
    public typealias StringLiteralType = String

    public var string: String
    public var initialValue: Double?
    
    override public var description: String {
        return self.string
    }
    
    override public var latex: String {
        return "\(self.string)"
    }
    
    override public var variables: Set<Variable> {
        return [self]
    }

    override public var derivatives: Set<Derivative> {
        return []
    }

    override public var typeIdentifier: String {
        return self.string
    }

    public static func ==(_ lhs: Variable, _ rhs: Variable) -> Bool {
        return lhs.string == rhs.string && lhs.initialValue == rhs.initialValue
    }
    
    public required init(stringLiteral str: String) {
        self.string = str
    }

    /// Initialize a variable using a string. The initial value is only used if the variable is the dependent variable in an ODE.
    ///
    /// - Parameters:
    ///   - str: String representation of the variable.
    ///   - initialValue: Initial value of the variable in an ODE. Won't be used and doesn't need to be specified if it is not the independent variable in an ODE.
    public convenience init(_ str: String, initialValue: Double? = nil) {
        self.init(stringLiteral: str)
        self.initialValue = initialValue
    }

    override public func getSymbol<Engine:SymbolicMathEngine>(using: Engine.Type) -> Engine.Symbol? {
        return Engine.new(self.string)
    }
    
    @inlinable
    override public func evaluate(withValues values: [Node : Double]) throws -> Double {
        if let value  = values[self] {
            return value
        } else {
            throw SymbolLabError.noValue(forVariable: self.description)
        }
    }

    override internal func equals(_ otherNode: Node) -> Bool {
        if let variable = otherNode as? Variable {
            return self.string == variable.string
        } else {
            return false
        }
    }

    override public func contains<T: Node>(nodeType: T.Type) -> [Id] {
        if(nodeType == Variable.self) {
            return [self.id]
        } else {
            return []
        }
    }

    @discardableResult override public func replace(_ targetNode: Node, with replacement: Node) -> Node {
        if(targetNode == self) {
            return replacement
        } else {
            return self
        }
    }

    override public func simplify() -> Node {
        return self
    }

    override public func hash(into hasher: inout Hasher) {
        hasher.combine("variable")
        hasher.combine(self.string)
    }
}
