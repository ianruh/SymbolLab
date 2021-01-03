public extension System {
    /// Solve a system of or container ODEs
    ///
    /// - Parameters:
    ///   - normalEqs:
    ///   - odes:
    ///   - pointsDict:
    ///   - initialGuess: Must be complete already
    ///   - threshold:
    ///   - maxIterations:
    ///   - backend:
    /// - Returns:
    /// - Throws:
    internal static func odeSolve<Engine: SymbolicMathEngine>(normalEqs: [Node],
                                                  odes: [(node: Node, dep: Variable, ind: Variable, derId: Id)],
                                                  at pointsDict: [Node: [Double]],
                                                  initialGuess: [Node: Double] = [:],
                                                  threshold: Double = 0.0001,
                                                  maxIterations: Int = 1000,
                                                  using backend: Engine.Type) throws -> (values: [[Node: Double]],
                                                                                         error: [Double],
                                                                                         iterations: [Int]) {
        // Verify that all the independent ODE variables are the same
        let indepedentVar = odes[0].ind
        for ode in odes {
            guard ode.ind == indepedentVar else {
                throw SymbolLabError.multipleIndependentVariables("cannot have both '\(indepedentVar)' and '\(ode.ind)'")
            }
        }
        // Verify that the points given are for the independent variable
        guard let points = pointsDict[indepedentVar] else {
            throw SymbolLabError.noValue(forVariable: "\(indepedentVar)")
        }

        // Construct normal system
        let normalSystem = System(normalEqs)

        // Dict to store the current values of all of dependent variables in the ODE
        var currentDeps: [Node: Double] = [:]
        for ode in odes {
            // Verify an initial value is given for all the indepedent ODE variables
            guard let initv = ode.dep.initialValue else {
                throw SymbolLabError.noValue(forVariable: "\(ode.dep) (no intial value given)")
            }
            currentDeps[ode.dep] = initv
        }

        // Replace all the derivatives with the new variables
        var newODEs: [(node: Node, dep: Variable, ind: Variable, newVar: Variable)] = []
        for ode in odes {
            // TODO: This is a stupid way to make a unique string. Probablyu fix when everything is converted from string to variable
            let newName = "\(ode.dep.string)d\(ode.ind.string)"
            let newVar = Variable(newName)
            _ = try ode.node.replace(id: ode.derId, with: newVar) // Will always return true, so we can ignore
            newODEs.append((node: ode.node, dep: ode.dep, ind: ode.ind, newVar: newVar))
        }

        // Construct the ODE system
        var odeSysArray: [Node] = []
        for ode in newODEs {
            odeSysArray.append(ode.node)
        }
        let odeSystem = System(odeSysArray)

        // Storage for values, errors, and iterations
        var values: [[Node:Double]] = []
        var errors: [Double] = []
        var iterations: [Int] = []

        // Loop through all the points
        for i in 0..<points.count-1 {
            // Construct the current constraints system
            var constraints: [Node] = []
            for ode in newODEs {
                constraints.append(ode.dep ~ Number(currentDeps[ode.dep]!))
            }

            // Solve the system
            let wholeSystem = normalSystem + odeSystem + System(constraints)
            let (val, err, n) = try wholeSystem.solve(guess: initialGuess, threshold: threshold, maxIterations: maxIterations, using: backend)

            // Update each dependent variable
            let h = points[i+1] - points[i]
            for ode in newODEs {
                let next = currentDeps[ode.dep]! + h*val[ode.newVar]!
                currentDeps[ode.dep] = next
            }

            // Store the values
            errors.append(err)
            iterations.append(n)
            var iterValues: [Node: Double] = [:]
            for key in val.keys {
                if(!newODEs.map({$0.newVar}).contains(key)) {
                    iterValues[key] = val[key]
                }
            }
            values.append(iterValues)
        }
        return (values: values, error: errors, iterations: iterations)
    }

    // public func solve<Engine: SymbolicMathEngine>(
    //     guess: [Node: Double] = [:], 
    //     threshold: Double = 0.0001, 
    //     maxIterations: Int = 1000, 
    //     using backend: Engine.Type) throws -> (values: [Node: Double], error: Double, iterations: Int) {

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
    public func solveODE<Engine: SymbolicMathEngine>(at points: [Double],
                      initialGuess: [Node: Double] = [:],
                      threshold: Double = 0.0001,
                      maxIterations: Int = 1000,
                      using backend: Engine.Type) throws -> (values: [[Node: Double]],
                                                            error: [Double],
                                                            iterations: [Int]) {

        // Verify we have at least one derivative
        let systemDerivatives = self.derivatives
        guard systemDerivatives.count > 0 else {
            throw SymbolLabError.notApplicable(message: "There does not appear to be any differential equations in the system.")
        }
        
        // Verify that all of the independent variables are the same.
        let firstIndependentVariable = systemDerivatives.first!.withRespectTo // Safe, because we just checked length
        for derivative in systemDerivatives {
            guard derivative.withRespectTo == firstIndependentVariable else {
                throw SymbolLabError.multipleIndependentVariables("Cannot have both independent variables '\(firstIndependentVariable)' and '\(derivative.withRespectTo)'")
            }

            guard derivative.diffOf as? Variable != nil else {
                throw SymbolLabError.misc("Only the derivative of a variable with respect to a variable is supported at this time.")
            }
        }

        // Dict to store the current values of all of dependent variables in the ODE
        var currentValues: [Node: Double] = [:]
        var associatedDeriavtives: [Node: Node] = [:]

        // Verify an initial value is given for all the indepedent ODE variables
        for derivative in systemDerivatives {
            guard let initv = (derivative.diffOf as! Variable).initialValue else {
                throw SymbolLabError.noValue(forVariable: "\(derivative.diffOf) (no intial value given)")
            }
            currentValues[derivative.diffOf] = initv
            associatedDeriavtives[derivative.diffOf] = derivative
        }

        // Storage for values, errors, and iterations
        var values: [[Node:Double]] = []
        var errors: [Double] = []
        var iterations: [Int] = []

        // Loop through all the points
        for i in 0..<points.count-1 {
            // Construct the current constraints system
            var constraints: [Node] = []
            for variable in currentValues.keys {
                constraints.append(variable ≈ Number(currentValues[variable]!))
            }

            // Solve the system
            let wholeSystem = self + System(constraints)
            var guess = initialGuess
            if(values.count > 0) {
                // Use the previous solution as the next guess
                guess = values.last!
            }
            let (val, err, n) = try wholeSystem.solve(guess: guess, threshold: threshold, maxIterations: maxIterations, using: backend)

            // Update each dependent variable
            let h = points[i+1] - points[i]
            for variable in currentValues.keys {
                currentValues[variable] = currentValues[variable]! + h*val[associatedDeriavtives[variable]!]!
            }

            // Store the values
            errors.append(err)
            iterations.append(n)
            values.append(val)
        }
        return (values: values, error: errors, iterations: iterations)
    }
}