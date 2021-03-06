import RealModule

public class Partial: Node, Function {
    public let identifier: String = "d"
    public let numArguments: Int = 2
    
    // Store the parameters for the node
    public var diffOf: Node
    public var withRespectTo: Node
    
    override public var description: String {
        return "∂(\(self.diffOf),\(self.withRespectTo))"
    }
    
    override public var latex: String {
        var topStr = "\(self.diffOf.latex)"
        var bottomStr = "\(self.withRespectTo.latex)"
        if(!self.diffOf.isBasic && !self.diffOf.isFunction) {
            topStr = "(\(topStr)"
        }
        if(!self.withRespectTo.isBasic) {
            bottomStr = "(\(bottomStr)"
        }
        return "\\frac{∂ \(topStr)}{∂ \(bottomStr)}"
    }
    
    // Look at note on Derivative.variables
    override public var variables: Set<Variable> {
        return []
    }

    override public var derivatives: Set<Derivative> {
        return []
    }

    override public var typeIdentifier: String {
        var hasher = Hasher()
        self.hash(into: &hasher)
        return "partial\(hasher.finalize())"
    }
    
    required public init(_ params: [Node]) {
        self.diffOf = params[0]
        self.withRespectTo = params[1]
    }

    public convenience init(of: Node, wrt: Node) {
        self.init([of, wrt])
    }

    override required public convenience init() {
        self.init([Node(), Node()])
    }

    override public func getSymbol<Engine:SymbolicMathEngine>(using type: Engine.Type) -> Engine.Symbol? {
        guard let of = self.diffOf.getSymbol(using: type) else {return nil}
        guard let v = self.withRespectTo.getSymbol(using: type) else {return nil}
        return Engine.partial(of: of, withRespectTo: v)
    }

    /// Attempt to evaluate symbolically, fall back on numerically, then fail. Prints an err message in debug mode if symolic evalutaion fails.
    ///
    /// The numerical evaluation does middle center difference, with h=sqrt(epsilon)*x.
    ///
    /// Wikipedia: For the numerical derivative formula evaluated at x and x + h, a choice for h that is small without producing a large rounding error is ε x {\displaystyle {\sqrt {\varepsilon }}x} {\displaystyle {\sqrt {\varepsilon }}x}
    ///
    /// - Parameter values: The values to evaluate at.
    /// - Returns: The value the node evaluates to at the given points.
    /// - Throws: If evaluation fails for some reason.
    @inlinable
    override public func evaluate(withValues values: [Node : Double]) throws -> Double {
        // Try numerically
        guard let variable = self.withRespectTo as? Variable else {
            // TODO: Numerical derivatives with respect to non-variables (aka other functions)
            throw SymbolLabError.misc("Derivatives with respect to non-variables hasn't been implemented yet.")
        }
        // assume machine precision ~ 2^-52
        let sqrtEpsilon = 0.000000014899
        let variableVal = try variable.evaluate(withValues: values)
        let h = variableVal*sqrtEpsilon
        var x_back = values
        x_back[variable]! -= h
        var x_forward = values
        x_forward[variable]! += h

        return try (self.diffOf.evaluate(withValues: x_forward) - self.diffOf.evaluate(withValues: x_back)) / (2*h)
    }

    override internal func equals(_ otherNode: Node) -> Bool {
        if let dir = otherNode as? Partial {
            return self.withRespectTo.equals(dir.withRespectTo) && self.diffOf.equals(dir.diffOf)
        } else {
            return false
        }
    }

    override public func contains<T: Node>(nodeType: T.Type) -> [Id] {
        var ids: [Id] = []
        if(nodeType == Partial.self) {
            ids.append(self.id)
        }
        ids.append(contentsOf: self.withRespectTo.contains(nodeType: nodeType))
        ids.append(contentsOf: self.diffOf.contains(nodeType: nodeType))
        return ids
    }

    @discardableResult override public func replace(_ targetNode: Node, with replacement: Node) -> Node {
        if(targetNode == self) {
            return replacement
        } else {
            return Partial(self.diffOf.replace(targetNode, with: replacement), self.withRespectTo.replace(targetNode, with: replacement))
        }
    }

    public override func simplify() -> Node {
        if let newNode = partial(of: self.diffOf.simplify(), wrt: self.withRespectTo.simplify()) {
            if let dif = newNode as? Partial {
                // To prevent recursion
                return newNode
            } else {
                return newNode.simplify()
            }
        } else {
            print("Unexpectedly found nil while simplifying a derivative: `\(self)`")
            return Number(0)
        }
    }

    override public func hash(into hasher: inout Hasher) {
        hasher.combine("partial")
        hasher.combine(self.diffOf)
        hasher.combine(self.withRespectTo)
    }
}