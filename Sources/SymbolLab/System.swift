//
//  File.swift
//  
//
//  Created by Ian Ruh on 8/14/20.
//

import Foundation
import LASwift

public class System: ExpressibleByArrayLiteral, CustomStringConvertible {
    public typealias ArrayLiteralElement = Node

    /// The set of variables involved in the system's equations
    public var variables: Set<Variable> {
        var variables: Set<Variable> = []
        equations.forEach({ eq in
            variables = variables.union(eq.variables)
        })
        return variables
    }

    /// The string representation of the system as a column array
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

    /// The ordered sequence of variables used whil solving the system
    public var variableSequence: [Variable] {
        return self.variables.sorted()
    }

    /// The Jacobian of the system, if one can be constructed
    public func getJacobian<Engine: SymbolicMathEngine>() -> Jacobian<Engine>? {
        return Jacobian<Engine>(system: self)
    }

    /// The set of equations that constitute the system
    internal var equations: [Node]

    /// Initializer is used when constructing the system
    ///
    /// - Parameter arrayLiteral: Array for the system
    public required init(arrayLiteral: ArrayLiteralElement...) {
        self.equations = arrayLiteral
    }

    /// Initializer to construct the system from an array of Nodes
    ///
    /// - Parameter array:
    public init(_ array: [Node]) {
        self.equations = array
    }

    /// Solve the system using Newton's method.
    ///
    /// - Parameters:
    ///   - guess: A dictionary of guess values for each of the variables in the system. If non is provided, then all guesses are assumed to be 1.
    ///   - threshold: The maximum acceptable error threshold. Iteration stops when this, or the maxIterations count is achieved.
    ///   - maxIterations: The maximum number of iterations to perform before stopping.
    /// - Returns: A vector of solutions to the system, ordered as is the system's veriableSequence.
    /// - Throws: An error for many reasons. Look at error message for details.
    public func solve<Engine: SymbolicMathEngine>(guess: [Node: Double] = [:], threshold: Double = 0.0001, maxIterations: Int = 1000, using backend: Engine.Type) throws -> (values: [Node: Double], error: Double, iterations: Int) {
        // Basic constraint check
        guard self.variables.count == self.equations.count else {
            throw SymbolLabError.misc("Unconstrained system.")
        }

        // Reformat equations
        let originalEquations = self.equations
        self.equations = self.formatAssignments(self.equations)
        defer {self.equations = originalEquations} // Restore the original set

        // Get the jacobian of the system
        guard let jacobian: Jacobian<Engine> = self.getJacobian() else {
            throw SymbolLabError.misc("Could not calculate Jacobian")
        }

        // Root vector
        let zero_vec = Vector(repeating: 0, count: self.equations.count)
        // Establish the first guess
        var x_current: Vector = []
        for v in self.variableSequence {
            if(guess.keys.contains(v)) {
                x_current.append(guess[v]!)
            } else {
                x_current.append(1)
            }
        }

        // Iterate
        var count = 0
        var err = try norm(LASwift.abs(self.eval(x_current)-zero_vec), 2)
        var shifted: Int = 0 // Whether or not we have shifted out of a singularity yet
        while(count < maxIterations && err > threshold) {
            var f = try self.eval(x_current)
            f = -1.0*f
            let J = try jacobian.eval(x_current)
            var y: [Double] = []
            // Try to solve the system
            do {
                y = try linsolve(J, Matrix(f)).flat // flat to get raw vector
            } catch {
                if(shifted < 3) {
                    for i in 0..<x_current.count {
                        // Alleviate the illconditioning by adding some noise (this is a magic amount of noise FYI)
                        x_current[i] += Double.random(in: -0.2...0.2)
                    }
                    shifted += 1
                    continue
                } else {
                    throw SymbolLabError.misc("System seems to be illconditioned.")
                }
            }
            x_current = x_current + y

            // Increment metrics
            err = try norm(LASwift.abs(self.eval(x_current)-zero_vec), 2)
            count += 1
        }

        var retVal: [Node: Double] = [:]
        for i in 0..<self.variableSequence.count {
            retVal[self.variableSequence[i]] = x_current[i]
        }
        return (retVal, err, count)
    }

    /// Evaluate the system at the point given by the dictionary of variables and values.
    ///
    /// - Parameter values: A dictionary of the value for each variable at the desired point.
    /// - Returns: The vector (ordered according to the variableSequence) for the value of the system at the point
    /// - Throws: On a multitude of occasions. Look at the error message for details.
    public func eval(_ values: [Node: Double]) throws -> Vector {
        var vec: Vector = []
        for eq in self.equations {
            try vec.append(eq.evaluate(withValues: values))
        }
        return vec
    }

    /// Evaluate the system at the given point.
    ///
    /// - Parameter vec: Values (assumed to be in order of variableSequence) to evaluate  at.
    /// - Returns: The vector for the value of the system at the point
    /// - Throws: On a multitude of occasions. Look at the error message for details
    public func eval(_ vec: Vector) throws -> Vector {
        var map = [Variable: Double]()
        guard vec.count == self.variables.count else {
            throw SymbolLabError.misc("Vector length doesn't match")
        }
        for i in 0..<vec.count {
            map[self.variableSequence[i]] = vec[i]
        }
        return try self.eval(map)
    }

    /// Reformat a set of equations to be equal to 0
    ///
    /// - Parameter equations: Equations to reformat
    /// - Returns: The reformated equations.
    internal func formatAssignments(_ equations: [Node]) -> [Node] {
        var copy = equations
        for i in 0..<copy.count {
            if let assignment = copy[i] as? Assign {
                copy[i] = assignment.left - assignment.right
            }
        }
        return copy
    }

    /// Compose two systems.
    ///
    /// - Parameters:
    ///   - lhs:
    ///   - rhs:
    /// - Returns: A new system with the constraints from both
    public static func +(_ lhs: System, _ rhs: System) -> System {
        var arr = lhs.equations
        arr.append(contentsOf: rhs.equations)
        return System(arr)
    }
}
