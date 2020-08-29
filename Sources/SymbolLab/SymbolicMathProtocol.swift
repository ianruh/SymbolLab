//
//  File.swift
//  
//
//  Created by Ian Ruh on 8/14/20.
//

public protocol SymbolicMathEngine {
    associatedtype Symbol

    // Utility
    static func constructNode(from symbol: Symbol) -> Node?

    static func new(_ integer: Int) -> Symbol
    static func new(_ double: Double) -> Symbol
    static func new(_ variable: String) -> Symbol

    // Misc
    static func expand(_ param: Symbol) -> Symbol?
    static func abs(_ param: Symbol) -> Symbol?
    static func erf(_ param: Symbol) -> Symbol?

    // SymbolType Operations
    static func add(_ lhs: Symbol, _ rhs: Symbol) -> Symbol
    static func subtract(_ lhs: Symbol, _ rhs: Symbol) -> Symbol
    static func divide(_ lhs: Symbol, _ rhs: Symbol) -> Symbol
    static func multiply(_ lhs: Symbol, _ rhs: Symbol) -> Symbol
    static func negate(_ item: Symbol) -> Symbol
    static func exponentiate(_ lhs: Symbol, _ rhs: Symbol) -> Symbol
    
    // Calc
    static func diff(of item: Symbol, withRespectTo: Symbol) -> Symbol?
    
    // Trig
    static func sin(_ term: Symbol) -> Symbol?
    static func cos(_ term: Symbol) -> Symbol?
    static func tan(_ term: Symbol) -> Symbol?
    
    // Other
    static func log(_ term: Symbol) -> Symbol?
    static func sqrt(_ term: Symbol) -> Symbol?
    static func exp(_ term: Symbol) -> Symbol?
}
