import Foundation
import Numerics

/// Subtract one node from the other.
public class Subtract: Node, Operation {
    
    public let precedence: OperationPrecedence = OperationPrecedence(higherThan: Assign().precedence)
    public let type: OperationType = .infix
    public let associativity: OperationAssociativity = .left
    public let identifier: String = "-"
    
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
        
        return "\(leftString)-\(rightString)"
    }
    
    override public var latex: String {
        return self.description
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
        return "subtraction\(hasher.finalize())"
    }
    
    required public init(_ params: [Node]) {
        self.left = params[0]
        self.right = params[1]
    }

    override required public init() {
        self.left = Node()
        self.right = Node()
        super.init()
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }

    override public func getSymbol<Engine:SymbolicMathEngine>(using type: Engine.Type) -> Engine.Symbol? {
        guard let left = self.left.getSymbol(using: type) else {return nil}
        guard let right = self.right.getSymbol(using: type) else {return nil}
        return Engine.subtract(left, right)
    }
    
    @inlinable
    override public func evaluate(withValues values: [Node: Double]) throws -> Double {
        return try self.left.evaluate(withValues: values) - self.right.evaluate(withValues: values)
    }

    override internal func equals(_ otherNode: Node) -> Bool {
        if let sub = otherNode as? Subtract {
            return self.left.equals(sub.left) && self.right.equals(sub.right)
        } else {
            return false
        }
    }

    override public func contains<T: Node>(nodeType: T.Type) -> [Id] {
        var ids: [Id] = []
        if(nodeType == Subtract.self) {
            ids.append(self.id)
        }
        ids.append(contentsOf: self.left.contains(nodeType: nodeType))
        ids.append(contentsOf: self.right.contains(nodeType: nodeType))
        return ids
    }

    @discardableResult override public func replace(_ targetNode: Node, with replacement: Node) -> Node {
        if(targetNode == self) {
            return replacement
        } else {
            return Subtract(self.left.replace(targetNode, with: replacement), self.right.replace(targetNode, with: replacement))
        }
    }

    public override func simplify() -> Node {
        let leftSimplified = self.left.simplify()
        let rightSimplified = self.right.simplify()

        // Test if both are numbers
        let leftIsNum = leftSimplified as? Number != nil
        let rightIsNum = rightSimplified as? Number != nil

        if(leftIsNum && rightIsNum) {
            return Number((leftSimplified as! Number).value - (rightSimplified as! Number).value)
        }
        
        return Add(leftSimplified, Multiply(Number(-1), rightSimplified).simplify()).simplify()
    }

    override public func hash(into hasher: inout Hasher) {
        hasher.combine("subtract")
        hasher.combine(self.left)
        hasher.combine(self.right)
    }
}