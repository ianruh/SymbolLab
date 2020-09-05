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
    public var variables: Set<String> {
        var variables: Set<String> = []
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
    public var variableSequence: [String] {
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
    public func solve<Engine: SymbolicMathEngine>(guess: [String: Double] = [:], threshold: Double = 0.0001, maxIterations: Int = 1000, using backend: Engine.Type) throws -> (values: [String: Double], error: Double, iterations: Int) {
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

        var retVal: [String: Double] = [:]
        for i in 0..<self.variableSequence.count {
            retVal[self.variableSequence[i]] = x_current[i]
        }
        return (retVal, err, count)
    }

    /// Solve the system over a range of values. Currently, only support a range for one value, but that is mostly just
    /// because the graphing library only has 2d support at the moment.
    ///
    ///
    /// - Parameters:
    ///   - overRange: A dictionary with the variable to vary associated with the desired range. e.g. `["x": 0.0..<10.0]`
    ///   - initialGuess: A set of initial guesses for the other variables at the beginning of the range.
    ///   - threshold: Same as solve without range.
    ///   - maxIterations: Same as solve without range.
    /// - Returns: The array of values, the array of errors, and the array of iterations.
    /// - Throws: For many reasons. Look at the return message.
    public func solve<Engine: SymbolicMathEngine>(overRange ranges: [String: Range<Double>],
                      withStride: Double,
                      initialGuess: [String: Double] = [:],
                      threshold: Double = 0.0001,
                      maxIterations: Int = 1000,
                      using backend: Engine.Type) throws -> (values: [[String: Double]],
                                                            error: [Double],
                                                            iterations: [Int]) {

        // Check we only have one variable
        guard ranges.count == 1 else {
            throw SymbolLabError.misc("Currently solve only can evaluate at one set of points.")
        }
        let (variable, range) = ranges.first!
        // Make our array
        let points: [String: [Double]] = [variable: Array(stride(from: range.lowerBound, to: range.upperBound, by: withStride))]
        return try self.solve(at: points, initialGuess: initialGuess, threshold: threshold, maxIterations: maxIterations, using: backend)
    }

    /// Solve the system over a range of values. Currently, only support a range for one value, but that is mostly just
    /// because the graphing library only has 2d support at the moment.
    ///
    ///
    /// - Parameters:
    ///   - overRange: A dictionary with the variable to vary associated with the desired range. e.g. `["x": 0.0..<10.0]`
    ///   - initialGuess: A set of initial guesses for the other variables at the beginning of the range.
    ///   - threshold: Same as solve without range.
    ///   - maxIterations: Same as solve without range.
    /// - Returns: The array of values, the array of errors, and the array of iterations.
    /// - Throws: For many reasons. Look at the return message.
    public func solve<Engine: SymbolicMathEngine>(overRange ranges: [String: ClosedRange<Double>],
                      withStride: Double,
                      initialGuess: [String: Double] = [:],
                      threshold: Double = 0.0001,
                      maxIterations: Int = 1000,
                      using backend: Engine.Type) throws -> (values: [[String: Double]],
                                                            error: [Double],
                                                            iterations: [Int]) {

        // Check we only have one variable
        guard ranges.count == 1 else {
            throw SymbolLabError.misc("Currently solve only can evaluate at one set of points.")
        }
        let (variable, range) = ranges.first!
        // Make our array
        let points: [String: [Double]] = [variable: Array(stride(from: range.lowerBound, through: range.upperBound, by: withStride))]
        return try self.solve(at: points, initialGuess: initialGuess, threshold: threshold, maxIterations: maxIterations, using: backend)
    }


    ///Solve the system at the given values. Currently, only support for one variable, but that is mostly because the
    /// plotting library only supports 2d at the moment.
    ///
    /// - Parameters:
    ///   - at: A dictionart associating a variable to a set of values. e.g. `["x": [0.0, 0.5, 1.0, 1.5, 2.0]]`
    ///   - initialGuess: A set of initial guesses for the other variables at the first element of the values.
    ///   - threshold:
    ///   - maxIterations:
    /// - Returns:
    /// - Throws:
    public func solve<Engine: SymbolicMathEngine>(at pointsDict: [String: [Double]],
                      initialGuess: [String: Double] = [:],
                      threshold: Double = 0.0001,
                      maxIterations: Int = 1000,
                      using backend: Engine.Type) throws -> (values: [[String: Double]],
                                                            error: [Double],
                                                            iterations: [Int]) {
        // Initialize the arrays that will store our data
        var values: [[String:Double]] = []
        var errors: [Double] = []
        var iterations: [Int] = []
        var guesses = initialGuess

        // Check the number of variables
        guard pointsDict.count == 1 else {
            throw SymbolLabError.misc("Currently solve only can evaluate at one set of points.")
        }
        guard self.equations.count+1 == self.variables.count else {
            throw SymbolLabError.misc("Unconstrained system.")
        }

        let (variable, points) = pointsDict.first! // We checked there will be exactly one

        // Construct initial guess
        for v in self.variables {
            if(!guesses.keys.contains(v)) {
                guesses[v] = 1
            }
        }

        // Start at the first element
        for point in points {
            // Add a temporary constraint for the current point
            // TODO: Don't construct the node by parsing. Fix this when you have math operators on nodes done
            self.equations.append(Variable(variable) ~ Decimal(floatLiteral: point))
            let (val, err, n) = try self.solve(guess: guesses, threshold: threshold, maxIterations: maxIterations, using: backend)
            values.append(val)
            errors.append(err)
            iterations.append(n)
            // Remove the constraint we just added
            self.equations.popLast()
            // Set the guesses to our current solutions (should be closer than 1,1,1,1,...)
            guesses = val
        }

        return (values, errors, iterations)
    }

    /// Evaluate the system at the point given by the dictionary of variables and values.
    ///
    /// - Parameter values: A dictionary of the value for each variable at the desired point.
    /// - Returns: The vector (ordered according to the variableSequence) for the value of the system at the point
    /// - Throws: On a multitude of occasions. Look at the error message for details.
    public func eval(_ values: [String: Double]) throws -> Vector {
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
        var map = [String: Double]()
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
    private func formatAssignments(_ equations: [Node]) -> [Node] {
        var copy = equations
        for i in 0..<copy.count {
            if let assignment = copy[i] as? Assign {
                copy[i] = assignment.left - assignment.right
            }
        }
        return copy
    }
}

public class Jacobian<Engine: SymbolicMathEngine>: CustomStringConvertible {
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
            guard let eqSymbol = eq.getSymbol(using: Engine.self) else {return nil}
            // Make row
            var row: [Node] = []
            for variable in variables {
                let node = Variable(variable)
                guard let nodeSymbol = node.getSymbol(using: Engine.self) else {return nil}
                guard let derivative = Engine.diff(of: eqSymbol, withRespectTo: nodeSymbol) else {return nil}
//                print("\(derivative.description)       --->      \(derivative.symbolLabString)")
                guard let derivativeNode = Engine.constructNode(from: derivative) else {return nil}
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
