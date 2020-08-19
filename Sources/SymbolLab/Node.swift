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
    /**
     Determine if the node is basic
     */
    public var isBasic: Bool {
        return self as? Number != nil || self as? Variable != nil
    }
    
    /**
    Determine if the node is an operation
    */
    public var isOperation: Bool {
        return self as? Operation != nil
    }
    
    /**
     Determine is the node is a function
     */
    public var isFunction: Bool {
        return self as? Function != nil
    }
}

public struct Number: Node {
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
