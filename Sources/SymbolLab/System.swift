//
//  File.swift
//  
//
//  Created by Ian Ruh on 8/14/20.
//

import Foundation
import SymEngine

public class System: ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = Node
    
    public var variables: Set<String> {
        var variables: Set<String> = []
        equations.forEach({ eq in
            variables = variables.union(eq.variables)
        })
        return variables
    }
    
    public var variableSequence: [String] {
        return self.variables.sorted()
    }
    
    public var equations: [Node]
    
    public required init(arrayLiteral: ArrayLiteralElement...) {
        self.equations = arrayLiteral
    }
    
    public init(_ array: [Node]) {
        self.equations = array
    }
    
    public func solve() {
        let jacobian = Jacobian(system: self)
        print(jacobian)
    }
    
    /**
    Check whether there are the same number of variables as equations.
     */
    public func checkNumberOfVariables() -> Bool {
        return self.variables.count == equations.count
    }
    
}

public class Jacobian: CustomStringConvertible {
    // Row major
    private var elements: [[SymEngine.Symbol]]
    
    public var description: String {
        var str: String = ""
        for row in self.elements {
            str += "["
            for el in row {
                str += "\(el),  "
            }
            str += "]\n"
        }
        return str
    }
    
    public var m: Int {
        return elements.count
    }
    
    public var n: Int {
        guard elements.count > 0 else {
            return 0
        }
        return elements[0].count
    }
    
    public init?(system: System) {
        let variables = system.variableSequence
        self.elements = []
        for eq in system.equations {
            // Make sure it is defined
            guard let eqSymbol = eq.symbol else {
                return nil
            }
            // Make row
            var row: [Symbol] = []
            for variable in variables {
                let node = Variable(variable)
                guard let derivative = SymEngine.diff(of: eqSymbol, withRespectTo: node.symbol!) else {
                    return nil
                }
                row.append(derivative)
            }
            // Append row
            self.elements.append(row)
        }
    }
    
//    public func eval(_ vec: [Double]) -> [[Double]] {
//
//    }
}
