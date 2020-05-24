//
//  File.swift
//  
//
//  Created by Ian Ruh on 5/14/20.
//

import SymEngine

//############################ Protocol and Precendence Definitions ##################

public enum OperationAssociativity {
    case left, none, right
}

public enum OperationType {
    case prefix, infix, postfix, function
}

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

public protocol Operation: Node {
    var precedence: OperationPrecedence {get}
    var type: OperationType {get}
    var associativity: OperationAssociativity {get}
    var identifier: String {get}
    
    init(_ params: [Node])
    
    func factory(_ params: [Node]) -> Node
}

// Useless, this is a hack
public struct Op: Operation {    
    public var precedence: OperationPrecedence = OperationPrecedence(higherThan: nil)
    public var type: OperationType = .infix
    public var associativity: OperationAssociativity = .none
    public var identifier: String = ""
    public init(_ params: [Node]) {}
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
    public var symbol: Symbol? = nil
    public var description: String = ""
    public var latex: String = ""
    
    public func generate(withOptions options: GeneratorOptions, depths: Depths = Depths()) -> Node {
        return Op([])
    }
}

public let P = Op([])

//############################ Basic Operations #############################

/**
Assign one node to the other.
*/
public struct Assign: Operation {
    // Nil means is the lowest possible precedence
    public let precedence: OperationPrecedence = OperationPrecedence(higherThan: nil)
    public let type: OperationType = .infix
    public let associativity: OperationAssociativity = .none
    public let identifier: String = "="
    
    // Store the parameters for the node
    private var left: Node
    private var right: Node
    
    public var description: String {
        // This is always true
        return "\(self.left)=\(self.right)"
    }
    
    public var symbol: Symbol? {
        // There is no corresponding representation in SymEngine
        return nil
    }
    
    public var latex: String {
        return "\(self.left.latex)=\(self.right.latex)"
    }
    
    public init(_ params: [Node]) {
        self.left = params[0]
        self.right = params[1]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
    
    public func generate(withOptions options: GeneratorOptions, depths: Depths = Depths()) -> Node {
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
}

/**
A negative number
*/
public struct Negative: Operation {
    public let precedence: OperationPrecedence = OperationPrecedence(higherThan: Parentheses([P,P]).precedence)
    public let type: OperationType = .prefix
    public let associativity: OperationAssociativity = .none
    public let identifier: String = "-"
    
    // Store the parameters for the node
    private var argument: Node
    
    public var description: String {
        guard self.argument.isBasic || self.argument as? Decimal != nil else {
            print("Missused negative operation : '-\(self.argument)'")
            return ""
        }
        return "-\(self.argument)"
    }
    
    public var symbol: Symbol? {
        return SymEngine.neg(self.argument.symbol)
    }
    
    public var latex: String {
        guard self.argument.isBasic || self.argument as? Decimal != nil else {
            print("Missused negative operation : '-\(self.argument)'")
            return ""
        }
        return "-\(self.argument.latex)"
    }
    
    public init(_ params: [Node]) {
        self.argument = params[0]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
    
    public func generate(withOptions options: GeneratorOptions, depths: Depths = Depths()) -> Node {
        // We don't need to make any copies here
        return Negative([Number(1).generate(withOptions: options, depths: depths)])
    }
}

/**
A decimal number
*/
public struct Decimal: Operation {
    public let precedence: OperationPrecedence = OperationPrecedence(higherThan: Negative([P,P]).precedence)
    public let type: OperationType = .infix
    public let associativity: OperationAssociativity = .none
    public let identifier: String = "."
    
    // Store the parameters for the node
    private var left: Node
    private var right: Node
    
    public var description: String {
        guard let leftNumber = self.left as? Number else {
            print("Missused decimal operation : '\(self.left).\(self.right)'")
            return ""
        }
        guard let rightNumber = self.right as? Number else {
            print("Missused decimal operation : '\(self.left).\(self.right)'")
            return ""
        }
        return "\(leftNumber).\(rightNumber)"
    }
    
    public var symbol: Symbol? {
        guard let leftNumber = self.left as? Number else {return nil}
        guard let rightNumber = self.right as? Number else {return nil}
        let valueOpt: Double? = Double("\(leftNumber).\(rightNumber)")
        if let value = valueOpt {
            return Symbol(value)
        }
        return nil
    }
    
    public var latex: String {
        guard let leftNumber = self.left as? Number else {
            print("Missused decimal operation : '\(self.left).\(self.right)'")
            return ""
        }
        guard let rightNumber = self.right as? Number else {
            print("Missused decimal operation : '\(self.left).\(self.right)'")
            return ""
        }
        return "\(leftNumber.latex).\(rightNumber.latex)"
    }
    
    public init(_ params: [Node]) {
        self.left = params[0]
        self.right = params[1]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
    
    public func generate(withOptions options: GeneratorOptions, depths: Depths = Depths()) -> Node {
        let newLeft = Number(1).generate(withOptions: options, depths: depths)
        let newRight = Number(1).generate(withOptions: options, depths: depths)
        return Decimal([newLeft, newRight])
    }
}

/**
Add one node to the other.
*/
public struct Add: Operation {
    
    public let precedence: OperationPrecedence = OperationPrecedence(higherThan: Assign([P,P]).precedence)
    public let type: OperationType = .infix
    public let associativity: OperationAssociativity = .left
    public let identifier: String = "+"
    
    // Store the parameters for the node
    private var left: Node
    private var right: Node
    
    public var description: String {
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
    
    public var symbol: Symbol? {
        return self.left.symbol + self.right.symbol
    }
    
    public var latex: String {
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
    
    public init(_ params: [Node]) {
        self.left = params[0]
        self.right = params[1]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
    
    public func generate(withOptions options: GeneratorOptions, depths: Depths = Depths()) -> Node {
        // Make copies
        var optionsCopy = options
        var depthsCopy = depths
        // Update depths
        depthsCopy.depth += 1
        
        let newLeft = GeneratorUtilities.randomNode(&optionsCopy, withDepths: depthsCopy)
        let newRight = GeneratorUtilities.randomNode(&optionsCopy, withDepths: depthsCopy)
        return Add([newLeft, newRight])
    }
}

/**
Subtract one node from the other.
*/
public struct Subtract: Operation {
    
    public let precedence: OperationPrecedence = OperationPrecedence(higherThan: Assign([P,P]).precedence)
    public let type: OperationType = .infix
    public let associativity: OperationAssociativity = .left
    public let identifier: String = "-"
    
    // Store the parameters for the node
    private var left: Node
    private var right: Node
    
    public var description: String {
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
    
    public var symbol: Symbol? {
        return self.left.symbol - self.right.symbol
    }
    
    public var latex: String {
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
    
    public init(_ params: [Node]) {
        self.left = params[0]
        self.right = params[1]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
    
    public func generate(withOptions options: GeneratorOptions, depths: Depths = Depths()) -> Node {
        // Make copies
        var optionsCopy = options
        var depthsCopy = depths
        // Update depths
        depthsCopy.depth += 1
        // ToDo: This isn't exactly what I want, because it disallows
        // 1-(-2), while I just want to disallow 1--2
        optionsCopy.remove(operation: Negative([P]))
        
        let newLeft = GeneratorUtilities.randomNode(&optionsCopy, withDepths: depthsCopy)
        let newRight = GeneratorUtilities.randomNode(&optionsCopy, withDepths: depthsCopy)
        return Subtract([newLeft, newRight])
    }
}

/**
Multiply one node by the other.
*/
public struct Multiply: Operation {
    
    public let precedence: OperationPrecedence = OperationPrecedence(higherThan: Add([P,P]).precedence)
    public let type: OperationType = .infix
    public let associativity: OperationAssociativity = .left
    public let identifier: String = "*"
    
    // Store the parameters for the node
    private var left: Node
    private var right: Node
    
    public var description: String {
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
    
    public var symbol: Symbol? {
        return self.left.symbol * self.right.symbol
    }
    
    public var latex: String {
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
    
    public init(_ params: [Node]) {
        self.left = params[0]
        self.right = params[1]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
    
    public func generate(withOptions options: GeneratorOptions, depths: Depths = Depths()) -> Node {
        // Make copies
        var optionsCopy = options
        var depthsCopy = depths
        // Update depths
        depthsCopy.depth += 1
        
        let newLeft = GeneratorUtilities.randomNode(&optionsCopy, withDepths: depthsCopy)
        let newRight = GeneratorUtilities.randomNode(&optionsCopy, withDepths: depthsCopy)
        return Multiply([newLeft, newRight])
    }
}

/**
Divide one node by the other.
*/
public struct Divide: Operation {
    
    public let precedence: OperationPrecedence = OperationPrecedence(higherThan: Add([P,P]).precedence)
    public let type: OperationType = .infix
    public let associativity: OperationAssociativity = .left
    public let identifier: String = "/"
    
    // Store the parameters for the node
    private var left: Node
    private var right: Node
    
    public var description: String {
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
    
    public var symbol: Symbol? {
        return self.left.symbol / self.right.symbol
    }
    
    public var latex: String {
        return "\\frac{\(self.left.latex)}{\(self.right.latex)}"
    }
    
    public init(_ params: [Node]) {
        self.left = params[0]
        self.right = params[1]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
    
    public func generate(withOptions options: GeneratorOptions, depths: Depths = Depths()) -> Node {
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
}

/**
Power of one node to the other.
*/
public struct Power: Operation {
    
    public let precedence: OperationPrecedence = OperationPrecedence(higherThan: Multiply([P,P]).precedence)
    public let type: OperationType = .infix
    public let associativity: OperationAssociativity = .right
    public let identifier: String = "^"
    
    // Store the parameters for the node
    private var left: Node
    private var right: Node
    
    public var description: String {
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
    
    public var symbol: Symbol? {
        return self.left.symbol ** self.right.symbol
    }
    
    public var latex: String {
        return "\(self.left.latex)^{\(self.right.latex)}"
    }
    
    public init(_ params: [Node]) {
        self.left = params[0]
        self.right = params[1]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
    public func generate(withOptions options: GeneratorOptions, depths: Depths = Depths()) -> Node {
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
}

/**
Factorial of a node.
*/
public struct Factorial: Operation {
    
    public let precedence: OperationPrecedence = OperationPrecedence(higherThan: Power([P,P]).precedence)
    public let type: OperationType = .postfix
    public let associativity: OperationAssociativity = .none
    public let identifier: String = "!"
    
    // Store the parameters for the node
    private var argument: Node
    
    public var description: String {
        // Wrap if needed
        if let op = self.argument as? Operation {
            if(op.type != .function) {
                return "(\(self.argument))!"
            }
        }
        
        return "\(self.argument)!"
    }
    
    public var symbol: Symbol? {
        #warning("Factorial has not been implemented yet.")
        return nil
    }
    
    public var latex: String {
        // Wrap if needed
        if let op = self.argument as? Operation {
            if(op.type != .function) {
                return "(\(self.argument.latex))!"
            }
        }
        
        return "\(self.argument.latex)!"
    }
    
    public init(_ params: [Node]) {
        self.argument = params[0]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
    
    public func generate(withOptions options: GeneratorOptions, depths: Depths = Depths()) -> Node {
        // Make copies
        var optionsCopy = options
        var depthsCopy = depths
        // Update depths
        depthsCopy.depth += 1
        
        let newParam = GeneratorUtilities.randomNode(&optionsCopy, withDepths: depthsCopy)
        return Factorial([newParam])
    }
}

