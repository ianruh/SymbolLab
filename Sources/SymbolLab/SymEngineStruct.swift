//
//  File.swift
//  
//
//  Created by Ian Ruh on 8/14/20.
//

import Foundation
import SymEngine

public struct SymEngineStruct: SymbolicMathEngine {
    public typealias SymbolType = Symbol
    
    public func new(_ real: Int, _ complex: Int) -> Symbol? {
        return Symbol(real, i: complex)
    }
    
    public func new(_ real: Double, _ complex: Double) -> Symbol? {
        return Symbol(real, i: complex)
    }
    
    public func new(_ variable: String) -> Symbol? {
        return Symbol(name: variable)
    }
    
    public func add(_ left: Symbol?, _ right: Symbol?) -> Symbol? {
        return left + right
    }
    
    public func subtract(_ left: Symbol?, _ right: Symbol?) -> Symbol? {
        return left - right
    }
    
    public func divide(_ left: Symbol?, _ right: Symbol?) -> Symbol? {
        return left / right
    }
    
    public func multiply(_ left: Symbol?, _ right: Symbol?) -> Symbol? {
        return left * right
    }
    
    public func negate(_ item: Symbol?) -> Symbol? {
        return -1 * item
    }
    
    public func exponentiate(_ left: Symbol?, _ right: Symbol?) -> Symbol? {
        return left**right
    }
    
    public func der(of item: Symbol?, withRespectTo: Symbol?) -> Symbol? {
        return SymEngine.diff(of: item, withRespectTo: withRespectTo)
    }
    
    public func sin(_ term: Symbol?) -> Symbol? {
        return SymEngine.sin(term)
    }
    
    public func cos(_ term: Symbol?) -> Symbol? {
        return SymEngine.cos(term)
    }
    
    public func tan(_ term: Symbol?) -> Symbol? {
        return SymEngine.tan(term)
    }
    
    public func log(_ term: Symbol?) -> Symbol? {
        return SymEngine.log(term)
    }
    
    public func sqrt(_ term: Symbol?) -> Symbol? {
        SymEngine.sqrt(term)
    }
    

}
