public extension System {

    public func minimize<Engine: SymbolicMathEngine>(_ cost: Node, using backend: Engine.Type) throws -> (values: [Node: Double], error: Double, iterations: Int) {
        var Z = cost
        let equations = self.formatAssignments(self.equations)
        for i in 0..<equations.count {
            Z = Z + Variable("λ\(i)")*equations[i]
        }

        let grad = Gradient(Z)
        return try grad.solve(using: backend)
    }
}