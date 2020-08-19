//
//  File.swift
//  
//
//  Created by Ian Ruh on 8/14/20.
//

import Foundation
import SymEngine
import LASwift

public class System: ExpressibleByArrayLiteral, CustomStringConvertible {
    public typealias ArrayLiteralElement = Node
    
    public var variables: Set<String> {
        var variables: Set<String> = []
        equations.forEach({ eq in
            variables = variables.union(eq.variables)
        })
        return variables
    }

    public var description: String {
        var str = "["
        for i in 0..<self.equations.count {
            str += "\(self.equations[i])"
            if(i != self.equations.count-1) {
                str += ",\n"
            }
        }
        str += "]"
        return str
    }
    
    public var variableSequence: [String] {
        return self.variables.sorted()
    }

    public var jacobian: Jacobian? {
        return Jacobian(system: self)
    }
    
    internal var equations: [Node]
    
    public required init(arrayLiteral: ArrayLiteralElement...) {
        self.equations = arrayLiteral
    }
    
    public init(_ array: [Node]) {
        self.equations = array
    }

    /**
    Solve the system using Newton's method.
    */
    public func solve(guess: [String: Double] = [:], threshold: Double = 0.0001, maxIterations: Int = 1000) throws -> Vector {
        guard self.checkNumberOfVariables() else {
            throw SymbolLabError.misc("Unconstrained system")
        }
        // Get the jacobian of the system
        guard let jacobian = self.jacobian else {
            throw SymbolLabError.misc("Could not calculate jacobian")
        }
        // Root vector
        let zero_vec = Vector(repeating: 0, count: self.equations.count)
        // Establish the first guess
        var x_current: Vector = []
        for v in self.variableSequence {
            if(guess.count != 0) {
                if(guess.keys.contains(v)) {
                    x_current.append(guess[v]!)
                } else {
                    throw SymbolLabError.misc("Guess not provided for variable '\(v)'")
                }
            } else {
                x_current.append(1)
            }
        }

        // Iterate
        var count = 0
        var err = norm(LASwift.abs(x_current-zero_vec), 2)
        while(count < maxIterations && err > threshold) {
            var f = try self.eval(x_current)
            f = -1.0*f
            let J = try jacobian.eval(x_current)
            let y = linsolve(J, Matrix(f)).flat // flat to get raw vector
            x_current = x_current + y

            // Increment metrics
            err = norm(LASwift.abs(x_current-zero_vec), 2)
            count += 1
        }

        return x_current
    }

    public func eval(_ values: [String: Double]) throws -> Vector {
        var vec: Vector = []
        for eq in self.equations {
            try vec.append(eq.evaluate(withValues: values))
        }
        return vec
    }

    /**
    Assume the values are in order of sequence
    */
    public func eval(_ vec: Vector) throws -> Vector {
        var map = [String: Double]()
        guard vec.count == self.variables.count else {
            throw SymbolLabError.misc("Vector length doesn't match")
        }
        for i in 0..<vec.count {
            map[self.variableSequence[i]] = vec[i]
        }
        return try self.eval(map)
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
    private var elements: [[Node]]
    private let system: System
    
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
        let parser = Parser()
        self.system = system
        let variables = system.variableSequence
        self.elements = []
        for eq in system.equations {
            // Make sure it is defined
            guard let eqSymbol = eq.symbol else {
                return nil
            }
            // Make row
            var row: [Node] = []
            for variable in variables {
                let node = Variable(variable)
                guard let derivative = SymEngine.diff(of: eqSymbol, withRespectTo: node.symbol!) else {
                    return nil
                }
//                print("\(derivative.description)       --->      \(derivative.symbolLabString)")
                guard let derivativeNode = parser.parse(cString: derivative.symbolLabString) else {
                    return nil
                }
                row.append(derivativeNode)
            }
            // Append row
            self.elements.append(row)
        }
    }

    public func eval(_ values: [String: Double]) throws -> Matrix {
        let variables = self.system.variableSequence
        // Check that all variables are represented
        for v in variables {
            if !values.keys.contains(v) {
                throw SymbolLabError.noValue(forVariable: v)
            }
        }
        // Evaluate each element
        var evaledJacobian: [[Double]] = []
        for row in 0..<self.m {
            evaledJacobian.append([])
            for col in 0..<self.n {
                evaledJacobian[row].append( try self.elements[row][col].evaluate(withValues: values) )
            }
        }
        return Matrix(evaledJacobian)
    }

    /**
    Assume the values are in order of sequence
    */
    public func eval(_ vec: Vector) throws -> Matrix {
        var map = [String: Double]()
        for i in 0..<vec.count {
            map[self.system.variableSequence[i]] = vec[i]
        }
        return try self.eval(map)
    }
}
