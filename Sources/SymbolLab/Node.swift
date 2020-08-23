//
//  File.swift
//  
//
//  Created by Ian Ruh on 5/14/20.
//

import SymEngine

public protocol Node: CustomStringConvertible {
    
    var symbol: Symbol? {get}
    var latex: String {get}
    var variables: Set<String> {get}
    
    func generate(withOptions options: GeneratorOptions, depths: Depths) -> Node
    func svg(using source: SVGSource) -> SVGElement?
    func evaluate(withValues values: [String: Double]) throws -> Double
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
    public static func **(_ lhs: Node, _ rhs: Node) -> Node {
        return Power([lhs, rhs])
    }
}

public struct Number: Node, ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = Int

    public var value: Int
    
    public var description: String {
        return "\(self.value)"
    }
    
    public var symbol: SymEngine.Symbol? {
        return Symbol(self.value)
    }
    
    public var latex: String {
        return "\(self.value)"
    }
    
    public var variables: Set<String> = []
    
    public init(_ num: Int) {
        self.value = num
    }

    public init(integerLiteral value: Int) {
        self.init(value)
    }
    
    public func generate(withOptions options: GeneratorOptions, depths: Depths = Depths()) -> Node {
        // No need to use the depths as this is a base node
        return Number(Int.random(withMaxDigits: options.numbers.maxWholeDigits))
    }
    
    public func svg(using source: SVGSource) -> SVGElement? {
        return SVGUtilities.svg(of: self.description, using: source)
    }
    
    public func evaluate(withValues values: [String : Double]) throws -> Double {
        return Double(self.value)
    }
}

public struct Variable: Node {
    public var string: String
    
    public var description: String {
        return self.string
    }
    
    public var symbol: Symbol? {
        return Symbol(name: self.string)
    }
    
    public var latex: String {
        return "\(self.string)"
    }
    
    public var variables: Set<String> {
        return [self.string]
    }
    
    public init(_ str: String) {
        self.string = str
    }
    
    public func generate(withOptions options: GeneratorOptions, depths: Depths = Depths()) -> Node {
        // No need to use the depths as this is a base node
        Variable(options.variables.names.randomElement()!)
    }
    
    public func svg(using source: SVGSource) -> SVGElement? {
        return SVGUtilities.svg(of: self.string, using: source)
    }
    
    public func evaluate(withValues values: [String : Double]) throws -> Double {
        guard values.keys.contains(self.string) else {
            throw SymbolLabError.noValue(forVariable: self.string)
        }
        return values[self.string]!
    }
}
