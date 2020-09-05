//
//  File.swift
//  
//
//  Created by Ian Ruh on 5/14/20.
//

public class Node: CustomStringConvertible {

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
    public var variables: Set<String> {
        preconditionFailure("variables should be overridden")
    }

    /// Determine if the node is basic
    public var isBasic: Bool {
        return self as? Number != nil || self as? Variable != nil
    }

    /// Determine if the node is an operation
    public var isOperation: Bool {
        return self as? Operation != nil
    }

    /// Determine is the node is a function
    public var isFunction: Bool {
        return self as? Function != nil
    }

    //------------------------ Functions ------------------------

    public func getSymbol<Engine:SymbolicMathEngine>(using: Engine.Type) -> Engine.Symbol? {
        preconditionFailure("This method must be overridden")
    }

    /// Generate random node with option. This should be overridden.
    public func generate(withOptions options: GeneratorOptions, depths: Depths) -> Node {
        preconditionFailure("This method must be overridden")
    }

    /// Get an svg of the node. This should be overridden.
    public func svg(using source: SVGSource) -> SVGElement? {
        preconditionFailure("This method must be overridden")
    }

    /// Evaluate the node. This should be overridden.
    public func evaluate(withValues values: [String: Double]) throws -> Double {
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

    /// Get the node with the given id.
    ///
    /// - Parameter id: Id of the node to get.
    /// - Returns: The node with the given id, if it exists in the tree.
    public func getNode(withId id: Id) -> Node? {
        preconditionFailure("This method must be overridden")
    }
}

public class Number: Node, ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = Int

    public var value: Int
    
    override public var description: String {
        return "\(self.value)"
    }

    override public var variables: Set<String> {
        return []
    }
    
    override public var latex: String {
        return "\(self.value)"
    }
    
    public init(_ num: Int) {
        self.value = num
    }

    required public convenience init(integerLiteral value: Int) {
        self.init(value)
    }

    public override func getSymbol<Engine: SymbolicMathEngine>(using: Engine.Type) -> Engine.Symbol? {
        return Engine.new(self.value)
    }

    override public func generate(withOptions options: GeneratorOptions, depths: Depths = Depths()) -> Node {
        // No need to use the depths as this is a base node
        return Number(Int.random(withMaxDigits: options.numbers.maxWholeDigits))
    }
    
    override public func svg(using source: SVGSource) -> SVGElement? {
        return SVGUtilities.svg(of: self.description, using: source)
    }
    
    override public func evaluate(withValues values: [String : Double]) throws -> Double {
        return Double(self.value)
    }

    override public func contains<T: Node>(nodeType: T.Type) -> [Id] {
        if(nodeType == Number.self) {
            return [self.id]
        } else {
            return []
        }
    }

    public override func replace(id: Id, with replacement: Node) throws -> Bool {
        guard id != self.id else {
            throw SymbolLabError.cannotReplaceNode("because cannot replace self.")
        }
        // There is nothing to replace, so just return false.
        return false;
    }

    public override func getNode(withId id: Id) -> Node? {
        if(self.id == id) {
            return self
        }
        return nil
    }
}

public class Variable: Node, ExpressibleByStringLiteral {
    public typealias StringLiteralType = String

    public var string: String
    
    override public var description: String {
        return self.string
    }
    
    override public var latex: String {
        return "\(self.string)"
    }
    
    override public var variables: Set<String> {
        return [self.string]
    }
    
    public required init(stringLiteral str: String) {
        self.string = str
    }

    public convenience init(_ str: String) {
        self.init(stringLiteral: str)
    }

    override public func getSymbol<Engine:SymbolicMathEngine>(using: Engine.Type) -> Engine.Symbol? {
        return Engine.new(self.string)
    }

    override public func generate(withOptions options: GeneratorOptions, depths: Depths = Depths()) -> Node {
        // No need to use the depths as this is a base node
        Variable(options.variables.names.randomElement()!)
    }
    
    override public func svg(using source: SVGSource) -> SVGElement? {
        return SVGUtilities.svg(of: self.string, using: source)
    }
    
    override public func evaluate(withValues values: [String : Double]) throws -> Double {
        guard values.keys.contains(self.string) else {
            throw SymbolLabError.noValue(forVariable: self.string)
        }
        return values[self.string]!
    }

    override public func contains<T: Node>(nodeType: T.Type) -> [Id] {
        if(nodeType == Variable.self) {
            return [self.id]
        } else {
            return []
        }
    }

    public override func replace(id: Id, with replacement: Node) throws -> Bool {
        guard id != self.id else {
            throw SymbolLabError.cannotReplaceNode("because cannot replace self.")
        }
        // There is nothing to replace, so just return false.
        return false;
    }

    public override func getNode(withId id: Id) -> Node? {
        if(self.id == id) {
            return self
        }
        return nil
    }
}
