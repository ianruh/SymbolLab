import Foundation
import Numerics

/// A negative number
public class Negative: Node, Operation {
    public let precedence: OperationPrecedence = OperationPrecedence(higherThan: Multiply().precedence)
    public let type: OperationType = .prefix
    public let associativity: OperationAssociativity = .none
    public let identifier: String = "-"
    
    // Store the parameters for the node
    public var argument: Node
    
    override public var description: String {
        return "-\(self.argument)"
    }
    
    override public var latex: String {
        return "-\(self.argument.latex)"
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
        return "negative\(hasher.finalize())"
    }
    
    required public init(_ params: [Node]) {
        self.argument = params[0]
    }

    override required public init() {
        self.argument = Node()
        super.init()
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }

    override public func getSymbol<Engine:SymbolicMathEngine>(using type: Engine.Type) -> Engine.Symbol? {
        guard let argumentSymbol = self.argument.getSymbol(using: type) else {
            return nil
        }
        return Engine.negate(argumentSymbol)
    }
    
    @inlinable
    override public func evaluate(withValues values: [Node : Double]) throws -> Double {
        return try -1*self.argument.evaluate(withValues: values)
    }

    override internal func equals(_ otherNode: Node) -> Bool {
        if let neg = otherNode as? Negative {
            return self.argument.equals(neg.argument)
        } else {
            return false
        }
    }

    override public func contains<T: Node>(nodeType: T.Type) -> [Id] {
        var ids: [Id] = []
        if(nodeType == Negative.self) {
            ids.append(self.id)
        }
        ids.append(contentsOf: self.argument.contains(nodeType: nodeType))
        return ids
    }

    @discardableResult override public func replace(_ targetNode: Node, with replacement: Node) -> Node {
        if(targetNode == self) {
            return replacement
        } else {
            return Negative(self.argument.replace(targetNode, with: replacement))
        }
    }

    public override func simplify() -> Node {
        return Multiply(Number(-1), self.argument.simplify())
    }

    override public func hash(into hasher: inout Hasher) {
        hasher.combine("negative")
        hasher.combine(self.argument)
    }
}