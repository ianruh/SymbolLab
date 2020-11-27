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
}