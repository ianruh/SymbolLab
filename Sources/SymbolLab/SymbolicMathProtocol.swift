//
//  File.swift
//  
//
//  Created by Ian Ruh on 8/14/20.
//

public protocol SymbolicMathEngine  {
    associatedtype SymbolType

    // Construct node
    var node: Node {get}
    
    // Factories
    func new(_ real: Int, _ complex: Int) -> SymbolType?
    func new(_ real: Double, _ complex: Double) -> SymbolType?
    func new(_ variable: String) -> SymbolType?
    
    // SymbolType Operations
    func add(_ left: SymbolType?, _ right: SymbolType?) -> SymbolType?
    func subtract(_ left: SymbolType?, _ right: SymbolType?) -> SymbolType?
    func divide(_ left: SymbolType?, _ right: SymbolType?) -> SymbolType?
    func multiply(_ left: SymbolType?, _ right: SymbolType?) -> SymbolType?
    func negate(_ item: SymbolType?) -> SymbolType?
    func exponentiate(_ left: SymbolType?, _ right: SymbolType?) -> SymbolType?
    
    // Calc
    func der(of item: SymbolType?, withRespectTo: SymbolType?) -> SymbolType?
    
    // Trig
    func sin(_ term: SymbolType?) -> SymbolType?
    func cos(_ term: SymbolType?) -> SymbolType?
    func tan(_ term: SymbolType?) -> SymbolType?
    
    // Other
    func log(_ term: SymbolType?) -> SymbolType?
    func sqrt(_ term: SymbolType?) -> SymbolType?
}
