//
//  File.swift
//  
//
//  Created by Ian Ruh on 5/14/20.
//

import SymEngine

public protocol Node: CustomStringConvertible {
    var symbol: SymEngine.Symbol? {get}
    var latex: String {get}
    var formalSVG: SVGElement? {get}
    
    func generate(withOptions options: GeneratorOptions, depths: Depths) -> Node
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
    
    public var formalSVG: SVGElement? {
        return SVGUtilities.svg(of: self.description)
    }
    
    public init(_ num: Int) {
        self.value = num
    }
    
    public func generate(withOptions options: GeneratorOptions, depths: Depths = Depths()) -> Node {
        // No need to use the depths as this is a base node
        return Number(Int.random(withMaxDigits: options.numbers.maxWholeDigits))
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
    
    public var formalSVG: SVGElement? {
        return SVGUtilities.svg(of: self.string)
    }
    
    public init(_ str: String) {
        self.string = str
    }
    
    public func generate(withOptions options: GeneratorOptions, depths: Depths = Depths()) -> Node {
        // No need to use the depths as this is a base node
        Variable(options.variables.names.randomElement()!)
    }
}
