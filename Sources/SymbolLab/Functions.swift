//
//  File.swift
//  
//
//  Created by Ian Ruh on 5/15/20.
//

import SymEngine

//######################### Define the protocol #########################

/**
 Protocol for a function. Example of the properties:
 
 $\int_0^2x^2dx$
 
 is written as 'int\[0,2\](x^2,x)'. So the identifier is 'int', the number of options is 2 because we
 have two bounds for the integral, and the number of arguments is 2 because we have the integrand
 and the differential.
 */
internal protocol Function: Operation {
    var numArguments: Int {get}
}

extension Function {
    var precedence: OperationPrecedence {
        OperationPrecedence(higherThan: Factorial([P,P]).precedence)
    }
    var type: OperationType {
        .function
    }
    var associativity: OperationAssociativity {
        .none
    }
}

//######################### Define the functions #########################

/**
 This is only for parsing to fit into the scheme. Otherwise it shouldn't be used because paretheses do nothing
 other than influence the order of operations.
 */
public struct Parentheses: Function {
    // No identifier
    internal let identifier: String = ""
    internal let numArguments: Int = 1
    
    private var param: Node // Store the parameter for the node
    
    public var symbol: Symbol? {
        return self.param.symbol
    }
    
    public var description: String {
        return "(\(self.param))"
    }
    
    init(_ params: [Node]) {
        self.param = params[0]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
}

public struct Derivative: Function {
    internal let identifier: String = "d"
    internal let numArguments: Int = 2
    
    // Store the parameters for the node
    private var diffOf: Node
    private var withRespectTo: Node
    
    public var symbol: Symbol? {
        return SymEngine.diff(of: self.diffOf.symbol, withRespectTo: self.withRespectTo.symbol)
    }
    
    public var description: String {
        return "d(\(self.diffOf), \(self.withRespectTo))"
    }
    
    init(_ params: [Node]) {
        self.diffOf = params[0]
        self.withRespectTo = params[1]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
}

public struct Integral: Function {
    internal let identifier: String = "int"
    internal let numArguments: Int = 4
    
    // Store the parameters for the node
    private var integrand: Node
    private var withRespectTo: Node
    private var lowerBound: Node
    private var upperBound: Node
    
    public var symbol: Symbol? {
        // Not currently implemented
        #warning("Integration has not been implemented yet in SymEngine")
        return nil
    }
    
    public var description: String {
        return "int(\(self.integrand),\(self.withRespectTo),\(self.lowerBound),\(self.upperBound))"
    }
    
    init(_ params: [Node]) {
        self.integrand = params[0]
        self.withRespectTo = params[1]
        self.lowerBound = params[2]
        self.upperBound = params[3]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
}

public struct Sin: Function {
    internal let identifier: String = "sin"
    internal let numOptions: Int = 0
    internal let numArguments: Int = 1
    
    // Store the parameters for the node
    private var argument: Node
    
    public var symbol: Symbol? {
        return sin(self.argument.symbol)
    }
    
    public var description: String {
        return "sin(\(self.argument))"
    }
    
    init(_ params: [Node]) {
        self.argument = params[0]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
}
