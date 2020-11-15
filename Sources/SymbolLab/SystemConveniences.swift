
public extension System {
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


    /// Solve the system at the given values. Currently, only support for one variable, but that is mostly because the
    /// plotting library only supports 2d at the moment.
    ///
    /// - Parameters:
    ///   - at: A dictionary associating a variable to a set of values. e.g. `["x": [0.0, 0.5, 1.0, 1.5, 2.0]]`
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
            throw SymbolLabError.misc("Under constrained system.")
        }

        // We've got a normal system from here on

        let (variable, points) = pointsDict.first! // We checked there will be exactly one

        // Construct initial guess
        for v in self.variables {
            if(!guesses.keys.contains(v)) {
                guesses[v] = 1
            }
        }

        // Handle ODEs by passing them off to odeSolve
        var normalEqs: [Node] = []
        var odes: [(node: Node, dep: Variable, ind: Variable, derId: Id)] = []
        for eq in self.equations {
            if let (dep, ind, derId) = eq.isODE {
                odes.append((node: eq, dep: dep, ind: ind, derId: derId))
            } else {
                normalEqs.append(eq)
            }
        }
        if(odes.count > 0) {
            return try System.odeSolve(normalEqs: normalEqs,
                    odes: odes,
                    at: pointsDict,
                    initialGuess: guesses,
                    threshold: threshold,
                    maxIterations: maxIterations,
                    using: backend)
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
            _ = self.equations.popLast()
            // Set the guesses to our current solutions (should be closer than 1,1,1,1,...)
            guesses = val
        }

        return (values, errors, iterations)
    }
}