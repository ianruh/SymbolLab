import Foundation
import Numerics

/// Power of one node to the other.
public class Power: Node, Operation {
    
    public let precedence: OperationPrecedence = OperationPrecedence(higherThan: Negative().precedence)
    public let type: OperationType = .infix
    public let associativity: OperationAssociativity = .right
    public let identifier: String = "^"
    
    // Store the parameters for the node
    public var left: Node
    public var right: Node
    
    override public var description: String {
        var leftString = "\(self.left)"
        var rightString = "\(self.right)"
        
        // Wrap the sides if needed
        if let op = self.left as? Operation {
            if(op.precedence < self.precedence && op.type == .infix) {
                leftString = "(\(leftString))"
            }
        }
        if let op = self.right as? Operation {
            if(op.precedence < self.precedence && op.type == .infix) {
                rightString = "(\(rightString))"
            }
        }
        
        return "\(leftString)^\(rightString)"
    }
    
    override public var latex: String {
        var leftString = self.left.latex
        if let op = self.left as? Operation {
            if(op.precedence < self.precedence && op.type == .infix) {
                leftString = "(\(leftString))"
            }
        }
        return "\(leftString)^{\(self.right.latex)}"
    }
    
    override public var variables: Set<Variable> {
        return self.left.variables + self.right.variables
    }

    override public var derivatives: Set<Derivative> {
        return self.left.derivatives + self.right.derivatives
    }

    override public var typeIdentifier: String {
        var hasher = Hasher()
        self.hash(into: &hasher)
        return "power\(hasher.finalize())"
    }
    
    required public init(_ params: [Node]) {
        self.left = params[0]
        self.right = params[1]
    }

    public init(_ left: Node, _ right: Node) {
        self.left = left
        self.right = right
    }

    override required public init() {
        self.left = Node()
        self.right = Node()
        super.init()
    }

    override public func getSymbol<Engine:SymbolicMathEngine>(using type: Engine.Type) -> Engine.Symbol? {
        guard let left = self.left.getSymbol(using: type) else {return nil}
        guard let right = self.right.getSymbol(using: type) else {return nil}
        return Engine.exponentiate(left, right)
    }
    
    @inlinable
    override public func evaluate(withValues values: [Node: Double]) throws -> Double {
        return try Double.pow(self.left.evaluate(withValues: values), self.right.evaluate(withValues: values))
    }

    override internal func equals(_ otherNode: Node) -> Bool {
        if let power = otherNode as? Power {
            return self.left.equals(power.left) && self.right.equals(power.right)
        } else {
            return false
        }
    }

    override public func contains<T: Node>(nodeType: T.Type) -> [Id] {
        var ids: [Id] = []
        if(nodeType == Power.self) {
            ids.append(self.id)
        }
        ids.append(contentsOf: self.left.contains(nodeType: nodeType))
        ids.append(contentsOf: self.right.contains(nodeType: nodeType))
        return ids
    }

    public override func simplify() -> Node {
        let leftSimplified = self.left.simplify()
        let rightSimplified = self.right.simplify()

        let leftIsNum = leftSimplified as? Number != nil
        let rightIsNum = rightSimplified as? Number != nil

        if(rightIsNum && (rightSimplified as! Number) == Number(1)) {
            return leftSimplified
        } else if(rightIsNum && (rightSimplified as! Number) == Number(0)) {
            return Number(1)
        } else if(leftIsNum && rightIsNum) {
            return Number(Double.pow((leftSimplified as! Number).value, (rightSimplified as! Number).value))
        }

        return Power(leftSimplified, rightSimplified)
    }

    override public func hash(into hasher: inout Hasher) {
        hasher.combine("power")
        hasher.combine(self.left)
        hasher.combine(self.right)
    }
}