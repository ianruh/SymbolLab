//
//  File.swift
//  
//
//  Created by Ian Ruh on 5/14/20.
//

public class Node: CustomStringConvertible {

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
}

extension Node {
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

    /// Add operator for nodes
    ///
    /// - Parameters:
    ///   - lhs: Left side of infix operation
    ///   - rhs: Right side of infix operation
    /// - Returns: New node adding the two
    public static func +(_ lhs: Node, _ rhs: Node) -> Node {
        return Add([lhs, rhs])
    }

    /// Subtract operator for nodes
    ///
    /// - Parameters:
    ///   - lhs:
    ///   - rhs:
    /// - Returns:
    public static func -(_ lhs: Node, _ rhs: Node) -> Node {
        return Subtract([lhs, rhs])
    }

    /// Divide operator for nodes
    ///
    /// - Parameters:
    ///   - lhs:
    ///   - rhs:
    /// - Returns:
    public static func /(_ lhs: Node, _ rhs: Node) -> Node {
        return Divide([lhs, rhs])
    }

    /// Multiply operator for nodes
    ///
    /// - Parameters:
    ///   - lhs:
    ///   - rhs:
    /// - Returns:
    public static func *(_ lhs: Node, _ rhs: Node) -> Node {
        return Multiply([lhs, rhs])
    }

    /// Take the lhs to the power of the rhs
    ///
    /// - Parameters:
    ///   - lhs:
    ///   - rhs:
    /// - Returns:
//    public static func **(_ lhs: Node, _ rhs: Node) -> Node {
//        return Power([lhs, rhs])
//    }
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
}

public class Variable: Node {
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
    
    public init(_ str: String) {
        self.string = str
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
}
