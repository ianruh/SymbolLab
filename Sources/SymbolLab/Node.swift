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
    
    /**
     This is  a bit of a hack. It will always be a PythonObject, but  I don't want to depend on
     PythonKit in this module. It should only be used in the SymbolLabTraining module.
     */
    var image: Any? {get}
    
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
    
    /**
     Default value for image. Should be overriden in the SymbolLabTraining Module.
     */
    public var image: Any? {
        return nil
    }
}

public struct Number: Node {
    var value: Int
    
    public var description: String {
        return "\(self.value)"
    }
    
    public var symbol: SymEngine.Symbol? {
        return Symbol(self.value)
    }
    
    public var latex: String {
        return "\(self.value)"
    }
    
    init(_ num: Int) {
        self.value = num
    }
    
    public func generate(withOptions options: GeneratorOptions, depths: Depths = Depths()) -> Node {
        // No need to use the depths as this is a base node
        return Number(Int.random(withMaxDigits: options.numbers.maxWholeDigits))
    }
}

public struct Variable: Node {
    var string: String
    
    public var description: String {
        return self.string
    }
    
    public var symbol: Symbol? {
        return Symbol(name: self.string)
    }
    
    public var latex: String {
        return "\(self.string)"
    }
    
    init(_ str: String) {
        self.string = str
    }
    
    public func generate(withOptions options: GeneratorOptions, depths: Depths = Depths()) -> Node {
        // No need to use the depths as this is a base node
        Variable(options.variables.names.randomElement()!)
    }
}
