//
//  File.swift
//  
//
//  Created by Ian Ruh on 5/14/20.
//

import SymEngine

public protocol Node: CustomStringConvertible {
    var symbol: SymEngine.Symbol? {get}
}

public struct Number: Node {
    var value: Int
    
    public var description: String {
        return "\(self.value)"
    }
    
    public var symbol: SymEngine.Symbol? {
        return Symbol(self.value)
    }
    
    init(_ num: Int) {
        self.value = num
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
    
    init(_ str: String) {
        self.string = str
    }
}
