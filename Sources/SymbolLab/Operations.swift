//
//  File.swift
//  
//
//  Created by Ian Ruh on 5/14/20.
//

import Foundation

//############################ Protocol and Precendence Definitions ##################

public enum OperationAssociativity {
    case left, none, right
}

public enum OperationType {
    case prefix, infix, postfix, function
}

/// Operation precedence struct.
public class OperationPrecedence: Comparable {
    var higherThan: OperationPrecedence?
    
    init(higherThan: OperationPrecedence?) {
        self.higherThan = higherThan
    }
    
    func getLevel() -> Int {
        var count: Int = 0
        var current: OperationPrecedence = self
        while(current.higherThan != nil) {
            count += 1
            current = current.higherThan!
        }
        return count
    }
    
    public static func < (lhs: OperationPrecedence, rhs: OperationPrecedence) -> Bool {
        return lhs.getLevel() < rhs.getLevel()
    }
    
    public static func == (lhs: OperationPrecedence, rhs: OperationPrecedence) -> Bool {
        return lhs.getLevel() == rhs.getLevel()
    }
}

/// The basic properties all opertaions need to have (plus a factory function)
public protocol Operation: Node {
    var precedence: OperationPrecedence {get}
    var type: OperationType {get}
    var associativity: OperationAssociativity {get}
    var identifier: String {get}
    
    init(_ params: [Node])
    init()
    
    func factory(_ params: [Node]) -> Node
}

//############################ Basic Operations #############################

/// Assign one node to the other.
public class Assign: Node, Operation {
    // Nil means is the lowest possible precedence
    public let precedence: OperationPrecedence = OperationPrecedence(higherThan: nil)
    public let type: OperationType = .infix
    public let associativity: OperationAssociativity = .none
    public let identifier: String = "="
    
    // Store the parameters for the node
    public var left: Node
    public var right: Node
    
    override public var description: String {
        // This is always true
        return "\(self.left)=\(self.right)"
    }
    
    override public var latex: String {
        return "\(self.left.latex)=\(self.right.latex)"
    }
    
    override public var variables: Set<String> {
        return self.left.variables + self.right.variables
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

    override public func getSymbol<Engine:SymbolicMathEngine>(using: Engine.Type) -> Engine.Symbol? {
        return nil
    }

    override public func generate(withOptions options: GeneratorOptions, depths: Depths = Depths()) -> Node {
        // Make copies
        var optionsCopy = options
        var depthsCopy = depths
        // Update depths
        depthsCopy.assignmentDepth += 1
        depthsCopy.depth += 1
        
        let newLeft = GeneratorUtilities.randomNode(&optionsCopy, withDepths: depthsCopy)
        let newRight = GeneratorUtilities.randomNode(&optionsCopy, withDepths: depthsCopy)
        return Assign([newLeft, newRight])
    }
    
    override public func svg(using source: SVGSource) -> SVGElement? {
        let leftSVGOpt = self.left.svg(using: source)
        let rightSVGOpt = self.right.svg(using: source)
        let opSVGOpt = source.getSymbol(self.identifier)
        guard let rightSVG = rightSVGOpt else { return nil }
        guard let leftSVG = leftSVGOpt else { return nil }
        guard let opSVG = opSVGOpt else { return nil }
        return SVGUtilities.compose(elements: [leftSVG, opSVG, rightSVG], spacing: SVGOptions.infixSpacing, alignment: .center, direction: .horizontal)
    }
    
    override public func evaluate(withValues values: [String : Double]) throws -> Double {
        throw SymbolLabError.notApplicable(message: "evaluate isn't applicable to assignment")
    }
}

/// A negative number
public class Negative: Node, Operation {
    public let precedence: OperationPrecedence = OperationPrecedence(higherThan: Multiply().precedence)
    public let type: OperationType = .prefix
    public let associativity: OperationAssociativity = .none
    public let identifier: String = "-"
    
    // Store the parameters for the node
    public var argument: Node
    
    override public var description: String {
        // MAYBE?
//        guard self.argument.isBasic || self.argument as? Decimal != nil else {
//            print("Missused negative operation : '-\(self.argument)'")
//            return ""
//        }
        return "-\(self.argument)"
    }
    
    override public var latex: String {
        // MAYBE?
//        guard self.argument.isBasic || self.argument as? Decimal != nil else {
//            print("Missused negative operation : '-\(self.argument)'")
//            return ""
//        }
        return "-\(self.argument.latex)"
    }
    
    override public var variables: Set<String> {
        return self.argument.variables
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

    override public func generate(withOptions options: GeneratorOptions, depths: Depths = Depths()) -> Node {
        // We don't need to make any copies here
        return Negative([Number(1).generate(withOptions: options, depths: depths)])
    }
    
    override public func svg(using source: SVGSource) -> SVGElement? {
        // MAYBE?
//        guard self.argument.isBasic || self.argument as? Decimal != nil else {
//            print("Missused negative operation : '-\(self.argument)'")
//            return nil
//        }
        let argSVGOpt = self.argument.svg(using: source)
        let opSVGOpt = source.getSymbol(self.identifier)
        guard let argSVG = argSVGOpt else { return nil }
        guard let opSVG = opSVGOpt else { return nil }
        return SVGUtilities.compose(elements: [opSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .center, direction: .horizontal)
    }
    
    override public func evaluate(withValues values: [String : Double]) throws -> Double {
        return try -1*self.argument.evaluate(withValues: values)
    }
}

/// A decimal number. Negatives are unknown here.
public class Decimal: Number, Operation, ExpressibleByFloatLiteral {
    public typealias FloatLiteralType = Double

    public let precedence: OperationPrecedence = OperationPrecedence(higherThan: Negative().precedence)
    public let type: OperationType = .infix
    public let associativity: OperationAssociativity = .none
    public let identifier: String = "."
    
    // Store the parameters for the node
    public var valueDouble: Double
    
    override public var description: String {
        return "\(self.valueDouble)"
    }
    
    override public var latex: String {
        return "\(self.valueDouble)"
    }
    
    override public var variables: Set<String> {
        return []
    }
    
    required public init(_ params: [Node]) {
        guard let leftNumber = params[0] as? Number else {
            preconditionFailure("Misused decimal. \(params[0]) is not a Number")
        }
        guard let rightNumber = params[1] as? Number else {
            preconditionFailure("Misused decimal. \(params[1]) is not a Number")
        }
        guard let value = Double("\(leftNumber).\(rightNumber)") else {
            preconditionFailure("Well not idea how this happens. But here you go: \(leftNumber).\(rightNumber) apparently can't be a Double")
        }
        self.valueDouble = value
        super.init(0)
    }

    public required init(floatLiteral value: Double) {
        self.valueDouble = value
        super.init(0)
    }

    required public convenience init(integerLiteral value: Int) {
        self.init(floatLiteral: Double(value))
    }

    public required init() {
        self.valueDouble = 0
        super.init(0)
    }

    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }

    override public func getSymbol<Engine:SymbolicMathEngine>(using: Engine.Type) -> Engine.Symbol? {
        return Engine.new(self.value)
    }

    override public func generate(withOptions options: GeneratorOptions, depths: Depths = Depths()) -> Node {
        let newLeft = Number(1).generate(withOptions: options, depths: depths)
        let newRight = Number(1).generate(withOptions: options, depths: depths)
        return Decimal([newLeft, newRight])
    }
    
    override public func svg(using source: SVGSource) -> SVGElement? {
        let leftSVGOpt = Number(self.valueDouble.whole).svg(using: source)
        let rightSVGOpt = Number(self.valueDouble.frac).svg(using: source)
        let opSVGOpt = source.getSymbol(self.identifier)
        guard let rightSVG = rightSVGOpt else { return nil }
        guard let leftSVG = leftSVGOpt else { return nil }
        guard let opSVG = opSVGOpt else { return nil }
        return SVGUtilities.compose(elements: [leftSVG, opSVG, rightSVG], spacing: SVGOptions.integerSpacing, alignment: .end, direction: .horizontal)
    }
    
    override public func evaluate(withValues values: [String : Double]) throws -> Double {
        return self.valueDouble
    }
}

/// Add one node to the other.
public class Add: Node, Operation {
    
    public let precedence: OperationPrecedence = OperationPrecedence(higherThan: Assign().precedence)
    public let type: OperationType = .infix
    public let associativity: OperationAssociativity = .left
    public let identifier: String = "+"
    
    // Store the parameters for the node
    private var left: Node
    private var right: Node
    
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
        
        return "\(leftString)+\(rightString)"
    }
    
    override public var latex: String {
        var leftString = "\(self.left.latex)"
        var rightString = "\(self.right.latex)"
        
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
        
        return "\(leftString)+\(rightString)"
    }
    
    override public var variables: Set<String> {
        return self.left.variables + self.right.variables
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
        return Engine.add(left, right)
    }

    override public func generate(withOptions options: GeneratorOptions, depths: Depths = Depths()) -> Node {
        // Make copies
        var optionsCopy = options
        var depthsCopy = depths
        // Update depths
        depthsCopy.depth += 1
        
        let newLeft = GeneratorUtilities.randomNode(&optionsCopy, withDepths: depthsCopy)
        let newRight = GeneratorUtilities.randomNode(&optionsCopy, withDepths: depthsCopy)
        return Add([newLeft, newRight])
    }
    
    override public func svg(using source: SVGSource) -> SVGElement? {
        let leftSVGOpt = self.left.svg(using: source)
        let rightSVGOpt = self.right.svg(using: source)
        let opSVGOpt = source.getSymbol(self.identifier)
        guard var rightSVG = rightSVGOpt else { return nil }
        guard var leftSVG = leftSVGOpt else { return nil }
        guard let opSVG = opSVGOpt else { return nil }
        
        // Wrap the sides if needed
        if let op = self.left as? Operation {
            if(op.precedence < self.precedence && op.type == .infix) {
                leftSVG = SVGUtilities.parentheses(leftSVG, using: source)
            }
        }
        if let op = self.right as? Operation {
            if(op.precedence < self.precedence && op.type == .infix) {
                rightSVG = SVGUtilities.parentheses(rightSVG, using: source)
            }
        }
        
        return SVGUtilities.compose(elements: [leftSVG, opSVG, rightSVG], spacing: SVGOptions.infixSpacing, alignment: .center, direction: .horizontal)
    }
    
    override public func evaluate(withValues values: [String : Double]) throws -> Double {
        return try self.left.evaluate(withValues: values) + self.right.evaluate(withValues: values)
    }
}

/// Subtract one node from the other.
public class Subtract: Node, Operation {
    
    public let precedence: OperationPrecedence = OperationPrecedence(higherThan: Assign().precedence)
    public let type: OperationType = .infix
    public let associativity: OperationAssociativity = .left
    public let identifier: String = "-"
    
    // Store the parameters for the node
    private var left: Node
    private var right: Node
    
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
        var leftString = "\(self.left.latex)"
        var rightString = "\(self.right.latex)"
        
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
    
    override public var variables: Set<String> {
        return self.left.variables + self.right.variables
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

    override public func generate(withOptions options: GeneratorOptions, depths: Depths = Depths()) -> Node {
        // Make copies
        var optionsCopy = options
        var depthsCopy = depths
        // Update depths
        depthsCopy.depth += 1
        // ToDo: This isn't exactly what I want, because it disallows
        // 1-(-2), while I just want to disallow 1--2
        optionsCopy.remove(operation: Negative())
        
        let newLeft = GeneratorUtilities.randomNode(&optionsCopy, withDepths: depthsCopy)
        let newRight = GeneratorUtilities.randomNode(&optionsCopy, withDepths: depthsCopy)
        return Subtract([newLeft, newRight])
    }
    
    override public func svg(using source: SVGSource) -> SVGElement? {
        let leftSVGOpt = self.left.svg(using: source)
        let rightSVGOpt = self.right.svg(using: source)
        let opSVGOpt = source.getSymbol(self.identifier)
        guard var rightSVG = rightSVGOpt else { return nil }
        guard var leftSVG = leftSVGOpt else { return nil }
        guard let opSVG = opSVGOpt else { return nil }
        
        // Wrap the sides if needed
        if let op = self.left as? Operation {
            if(op.precedence < self.precedence && op.type == .infix) {
                leftSVG = SVGUtilities.parentheses(leftSVG, using: source)
            }
        }
        if let op = self.right as? Operation {
            if(op.precedence < self.precedence && op.type == .infix) {
                rightSVG = SVGUtilities.parentheses(rightSVG, using: source)
            }
        }
        
        return SVGUtilities.compose(elements: [leftSVG, opSVG, rightSVG], spacing: SVGOptions.infixSpacing, alignment: .center, direction: .horizontal)
    }
    
    override public func evaluate(withValues values: [String : Double]) throws -> Double {
        return try self.left.evaluate(withValues: values) - self.right.evaluate(withValues: values)
    }
}

/// Multiply one node by the other.
public class Multiply: Node, Operation {
    
    public let precedence: OperationPrecedence = OperationPrecedence(higherThan: Add().precedence)
    public let type: OperationType = .infix
    public let associativity: OperationAssociativity = .left
    public let identifier: String = "*"
    
    // Store the parameters for the node
    private var left: Node
    private var right: Node
    
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
        
        return "\(leftString)*\(rightString)"
    }
    
    override public var latex: String {
        var leftString = "\(self.left.latex)"
        var rightString = "\(self.right.latex)"
        
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
        
        return "\(leftString)\\cdot \(rightString)"
    }
    
    override public var variables: Set<String> {
        return self.left.variables + self.right.variables
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
        return Engine.multiply(left, right)
    }

    override public func generate(withOptions options: GeneratorOptions, depths: Depths = Depths()) -> Node {
        // Make copies
        var optionsCopy = options
        var depthsCopy = depths
        // Update depths
        depthsCopy.depth += 1
        
        let newLeft = GeneratorUtilities.randomNode(&optionsCopy, withDepths: depthsCopy)
        let newRight = GeneratorUtilities.randomNode(&optionsCopy, withDepths: depthsCopy)
        return Multiply([newLeft, newRight])
    }
    
    override public func svg(using source: SVGSource) -> SVGElement? {
        let leftSVGOpt = self.left.svg(using: source)
        let rightSVGOpt = self.right.svg(using: source)
        let opSVGOpt = source.getSymbol(self.identifier)
        guard var rightSVG = rightSVGOpt else { return nil }
        guard var leftSVG = leftSVGOpt else { return nil }
        guard let opSVG = opSVGOpt else { return nil }
        
        // Wrap the sides if needed
        if let op = self.left as? Operation {
            if(op.precedence < self.precedence && op.type == .infix) {
                leftSVG = SVGUtilities.parentheses(leftSVG, using: source)
            }
        }
        if let op = self.right as? Operation {
            if(op.precedence < self.precedence && op.type == .infix) {
                rightSVG = SVGUtilities.parentheses(rightSVG, using: source)
            }
        }
        
        return SVGUtilities.compose(elements: [leftSVG, opSVG, rightSVG], spacing: SVGOptions.infixSpacing, alignment: .center, direction: .horizontal)
    }
    
    override public func evaluate(withValues values: [String : Double]) throws -> Double {
        return try self.left.evaluate(withValues: values) * self.right.evaluate(withValues: values)
    }
}

/// Divide one node by the other.
public class Divide: Node, Operation {
    
    public let precedence: OperationPrecedence = OperationPrecedence(higherThan: Add().precedence)
    public let type: OperationType = .infix
    public let associativity: OperationAssociativity = .left
    public let identifier: String = "/"
    
    // Store the parameters for the node
    private var left: Node
    private var right: Node
    
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
        
        return "\(leftString)/\(rightString)"
    }
    
    override public var latex: String {
        return "\\frac{\(self.left.latex)}{\(self.right.latex)}"
    }
    
    override public var variables: Set<String> {
        return self.left.variables + self.right.variables
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
        return Engine.divide(left, right)
    }

    override public func generate(withOptions options: GeneratorOptions, depths: Depths = Depths()) -> Node {
        // Make copies
        var optionsCopy = options
        var depthsCopy = depths
        // Update depths
        depthsCopy.fractionDepth += 1
        depthsCopy.depth += 1
        
        let newLeft = GeneratorUtilities.randomNode(&optionsCopy, withDepths: depthsCopy)
        let newRight = GeneratorUtilities.randomNode(&optionsCopy, withDepths: depthsCopy)
        return Divide([newLeft, newRight])
    }
    
    override public func svg(using source: SVGSource) -> SVGElement? {
        let leftSVGOpt = self.left.svg(using: source)
        let rightSVGOpt = self.right.svg(using: source)
        let barSVGOpt = source.getSymbol("-")
        guard let rightSVG = rightSVGOpt else { return nil }
        guard let leftSVG = leftSVGOpt else { return nil }
        guard var barSVG = barSVGOpt else { return nil }
        
        guard let rightBB = rightSVG.boundingBox else { return nil }
        guard let leftBB = leftSVG.boundingBox else { return nil }
        barSVG.resize(width: max(rightBB.width, leftBB.width), height: SVGOptions.fractionBarThickness)
        
        return SVGUtilities.compose(elements: [leftSVG, barSVG, rightSVG], spacing: SVGOptions.fractionSpacing, alignment: .center, direction: .vertical)
    }
    
    override public func evaluate(withValues values: [String : Double]) throws -> Double {
        return try self.left.evaluate(withValues: values) / self.right.evaluate(withValues: values)
    }
}

/// Power of one node to the other.
public class Power: Node, Operation {
    
    public let precedence: OperationPrecedence = OperationPrecedence(higherThan: Negative().precedence)
    public let type: OperationType = .infix
    public let associativity: OperationAssociativity = .right
    public let identifier: String = "^"
    
    // Store the parameters for the node
    private var left: Node
    private var right: Node
    
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
    
    override public var variables: Set<String> {
        return self.left.variables + self.right.variables
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
        return Engine.exponentiate(left, right)
    }

    override public func generate(withOptions options: GeneratorOptions, depths: Depths = Depths()) -> Node {
        // Make copies
        var optionsCopy = options
        var depthsCopy = depths
        // Update depths
        depthsCopy.exponentDepth += 1
        depthsCopy.depth += 1
        
        let newLeft = GeneratorUtilities.randomNode(&optionsCopy, withDepths: depthsCopy)
        let newRight = GeneratorUtilities.randomNode(&optionsCopy, withDepths: depthsCopy)
        return Power([newLeft, newRight])
    }
    
    override public func svg(using source: SVGSource) -> SVGElement? {
        let leftSVGOpt = self.left.svg(using: source)
        let rightSVGOpt = self.right.svg(using: source)
        guard var leftSVG = leftSVGOpt else { return nil }
        guard var rightSVG = rightSVGOpt else { return nil }
        
        if let op = self.left as? Operation {
            if(op.precedence < self.precedence && op.type == .infix) {
                leftSVG = SVGUtilities.parentheses(leftSVG, using: source)
            }
        }
        
        rightSVG.scale(by: 0.5)
        guard let leftBB = leftSVG.boundingBox else { return nil }
        
        let svg: SVG = SVG(children: [])
        svg.paste(path: leftSVG, withTopLeftAt: Point(0,0))
        svg.paste(path: rightSVG, withCenterLeftAt: Point(leftBB.width + SVGOptions.powerSpacing, 0))
        svg.minimizeSVG()
        return svg
    }
    
    override public func evaluate(withValues values: [String : Double]) throws -> Double {
        return try pow(self.left.evaluate(withValues: values), self.right.evaluate(withValues: values))
    }
}

/// Factorial of a node.
public class Factorial: Node, Operation {
    
    public let precedence: OperationPrecedence = OperationPrecedence(higherThan: Power().precedence)
    public let type: OperationType = .postfix
    public let associativity: OperationAssociativity = .none
    public let identifier: String = "!"
    
    // Store the parameters for the node
    private var argument: Node
    
    override public var description: String {
        // Wrap if needed
        if let op = self.argument as? Operation {
            if(op.type != .function) {
                return "(\(self.argument))!"
            }
        }
        
        return "\(self.argument)!"
    }
    
    override public var latex: String {
        // Wrap if needed
        if let op = self.argument as? Operation {
            if(op.type != .function) {
                return "(\(self.argument.latex))!"
            }
        }
        
        return "\(self.argument.latex)!"
    }
    
    override public var variables: Set<String> {
        return self.argument.variables
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
        // TODO: Factorial in symbolic math protocol
        return nil
    }

    override public func generate(withOptions options: GeneratorOptions, depths: Depths = Depths()) -> Node {
        // Make copies
        var optionsCopy = options
        var depthsCopy = depths
        // Update depths
        depthsCopy.depth += 1
        
        let newParam = GeneratorUtilities.randomNode(&optionsCopy, withDepths: depthsCopy)
        return Factorial([newParam])
    }
    
    override public func svg(using source: SVGSource) -> SVGElement? {
        let argSVGOpt = argument.svg(using: source)
        guard var argSVG = argSVGOpt else { return nil }
        guard let opSVG = source.getSymbol("!") else { return nil }
        
        // Wrap if needed
        if let op = self.argument as? Operation {
            if(op.type != .function) {
                argSVG = SVGUtilities.parentheses(argSVG, using: source)
            }
        }
        
        return SVGUtilities.compose(elements: [argSVG, opSVG], spacing: SVGOptions.parethesesSpacing, alignment: .end, direction: .horizontal)
    }
    
    override public func evaluate(withValues values: [String : Double]) throws -> Double {
        // TODO: Factorial evaluation
        throw SymbolLabError.notApplicable(message: "Factorial not implemented for the moment")
    }
}

