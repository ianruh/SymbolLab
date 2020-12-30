import RealModule

/// The natural log function
///
public class Log: Node, Function {
    public let identifier: String = "log"
    public let numArguments: Int = 1
    
    // Store the parameters for the node
    public var argument: Node
    
    override public var description: String {
        return "log(\(self.argument))"
    }
    
    override public var latex: String {
        return "\\log(\(self.argument.latex))"
    }
    
    override public var variables: Set<Variable> {
        return self.argument.variables
    }

    override public var derivatives: Set<Derivative> {
        return self.argument.derivatives
    }

    override public var typeIdentifier: String {
        var hasher = Hasher()
        self.hash(into: &hasher)
        return "logarithm\(hasher.finalize())"
    }
    
    required public init(_ params: [Node]) {
        self.argument = params[0]
    }

    public convenience init(_ param: Node) {
        self.init([param])
    }

    override required public convenience init() {
        self.init([Node()])
    }

    override public func getSymbol<Engine:SymbolicMathEngine>(using type: Engine.Type) -> Engine.Symbol? {
        guard let param = self.argument.getSymbol(using: type) else {return nil}
        return Engine.log(param)
    }

    @inlinable
    override public func evaluate(withValues values: [Node: Double]) throws -> Double {
        return try Double.log(self.argument.evaluate(withValues: values))
    }

    override internal func equals(_ otherNode: Node) -> Bool {
        if let log = otherNode as? Log {
            return self.argument.equals(log.argument)
        } else {
            return false
        }
    }

    override public func contains<T: Node>(nodeType: T.Type) -> [Id] {
        var ids: [Id] = []
        if(nodeType == Log.self) {
            ids.append(self.id)
        }
        ids.append(contentsOf: self.argument.contains(nodeType: nodeType))
        return ids
    }

    public override func simplify() -> Node {
        return Log(self.argument.simplify())
    }

    override public func hash(into hasher: inout Hasher) {
        hasher.combine("naturallog")
        hasher.combine(self.argument)
    }
}