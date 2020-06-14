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
public protocol Function: Operation {
    var numArguments: Int {get}
}

extension Function {
    public var precedence: OperationPrecedence {
        OperationPrecedence(higherThan: Factorial([P,P]).precedence)
    }
    public var type: OperationType {
        .function
    }
    public var associativity: OperationAssociativity {
        .none
    }
    
    /**
     Default implementation of generater for functions. Can be overridden by speicifc functions.
     */
    public func generate(withOptions options: GeneratorOptions, depths: Depths = Depths()) -> Node {
        // Make copies
        var optionsCopy = options
        var depthsCopy = depths
        // Update depths
        depthsCopy.functionDepth += 1
        depthsCopy.depth += 1
        
        // Create needed nodes
        var params: [Node] = []
        for _ in 0..<self.numArguments {
            params.append(GeneratorUtilities.randomNode(&optionsCopy, withDepths: depthsCopy))
        }
        
        return self.factory(params)
    }
}

//######################### Define the functions #########################

/**
 This is only for parsing to fit into the scheme. Otherwise it shouldn't be used because paretheses do nothing
 other than influence the order of operations.
 */
public struct Parentheses: Function {
    // No identifier
    public let identifier: String = ""
    public let numArguments: Int = 1
    
    private var param: Node // Store the parameter for the node
    
    public var symbol: Symbol? {
        return self.param.symbol
    }
    
    public var description: String {
        return "(\(self.param))"
    }
    
    public var latex: String {
        return "(\(self.param.latex))"
    }
    
    public var formalSVG: SVGElement? {
        let argSVGOpt = self.param.formalSVG
        guard let argSVG = argSVGOpt else { return nil }
        return SVGUtilities.formalParentheses(argSVG)
    }
    
    public init(_ params: [Node]) {
        self.param = params[0]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
    
    public func generate(withOptions options: GeneratorOptions, depths: Depths = Depths()) -> Node {
        // Make copies
        var optionsCopy = options
        var depthsCopy = depths
        // We don't consider parentheses a real function
        // depthsCopy.functionDepth += 1
        depthsCopy.depth += 1
        
        // Create needed nodes
        var params: [Node] = []
        for _ in 0..<self.numArguments {
            params.append(GeneratorUtilities.randomNode(&optionsCopy, withDepths: depthsCopy))
        }
        
        return self.factory(params)
    }
}

public struct Derivative: Function {
    public let identifier: String = "d"
    public let numArguments: Int = 2
    
    // Store the parameters for the node
    private var diffOf: Node
    private var withRespectTo: Node
    
    public var symbol: Symbol? {
        return SymEngine.diff(of: self.diffOf.symbol, withRespectTo: self.withRespectTo.symbol)
    }
    
    public var description: String {
        return "d(\(self.diffOf),\(self.withRespectTo))"
    }
    
    public var latex: String {
        var topStr = "\(self.diffOf.latex)"
        var bottomStr = "\(self.withRespectTo.latex)"
        if(!self.diffOf.isBasic && !self.diffOf.isFunction) {
            topStr = "(\(topStr)"
        }
        if(!self.withRespectTo.isBasic) {
            bottomStr = "(\(bottomStr)"
        }
        return "\\frac{d \(topStr)}{d \(bottomStr)}"
    }
    
    public var formalSVG: SVGElement? {
        #warning("Not implemented yet")
        return nil
    }
    
    public init(_ params: [Node]) {
        self.diffOf = params[0]
        self.withRespectTo = params[1]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
    
    public func generate(withOptions options: GeneratorOptions, depths: Depths = Depths()) -> Node {
        // Make copies
        var optionsCopy = options
        var depthsCopy = depths
        // We don't consider parentheses a real function
        // depthsCopy.functionDepth += 1
        depthsCopy.depth += 1
        
        // Create needed nodes
        var params: [Node] = []
        for _ in 0..<self.numArguments {
            params.append(GeneratorUtilities.randomNode(&optionsCopy, withDepths: depthsCopy))
        }
        
        return self.factory(params)
    }
}

public struct Integral: Function {
    public let identifier: String = "int"
    public let numArguments: Int = 4
    
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
    
    public var latex: String {
        let bottomStr = "\(self.lowerBound.latex)"
        let topStr = "\(self.upperBound.latex)"
        let integrandStr = "\(self.integrand.latex)"
        var withRespectToStr = "\(self.withRespectTo.latex)"
        if(!self.withRespectTo.isBasic) {
            withRespectToStr = "(\(withRespectToStr))"
        }
        
        return "\\int_{\(bottomStr)}^{\(topStr)} \(integrandStr) d\(withRespectToStr)"
    }
    
    public var formalSVG: SVGElement? {
        #warning("Not implemented yet")
        return nil
    }
    
    public init(_ params: [Node]) {
        self.integrand = params[0]
        self.withRespectTo = params[1]
        self.lowerBound = params[2]
        self.upperBound = params[3]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
}

public struct Expand: Function {
    public let identifier: String = "expand"
    public let numArguments: Int = 1
    
    // Store the parameters for the node
    private var argument: Node
    
    public var symbol: Symbol? {
        return expand(self.argument.symbol)
    }
    
    public var description: String {
        return "expand(\(self.argument))"
    }
    
    // There is no equivalent of this as this isn't really mathematical
    public var latex: String {
        return self.argument.latex
    }
    
    public var formalSVG: SVGElement? {
        guard let nameSVG = SVGUtilities.svg(of: self.identifier) else { return nil }
        guard var argSVG = self.argument.formalSVG else { return nil }
        argSVG = SVGUtilities.formalParentheses(argSVG)
        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .end, direction: .horizontal)
    }
    
    public init(_ params: [Node]) {
        self.argument = params[0]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
}

public struct AbsoluteValue: Function {
    public let identifier: String = "abs"
    public let numArguments: Int = 1
    
    // Store the parameters for the node
    private var argument: Node
    
    public var symbol: Symbol? {
        return abs(self.argument.symbol)
    }
    
    public var description: String {
        return "abs(\(self.argument))"
    }
    
    public var latex: String {
        return "\\left| \(self.argument.latex) \\right|"
    }
    
    public var formalSVG: SVGElement? {
        #warning("Not implemented yet")
        return nil
    }
    
    public init(_ params: [Node]) {
        self.argument = params[0]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
}

public struct ErrorFunction: Function {
    public let identifier: String = "erf"
    public let numArguments: Int = 1
    
    // Store the parameters for the node
    private var argument: Node
    
    public var symbol: Symbol? {
        return erf(self.argument.symbol)
    }
    
    public var description: String {
        return "erf(\(self.argument))"
    }
    
    public var latex: String {
        return "\\textrm{erf}(\(self.argument.latex))"
    }
    
    public var formalSVG: SVGElement? {
        guard let nameSVG = SVGUtilities.svg(of: self.identifier) else { return nil }
        guard var argSVG = self.argument.formalSVG else { return nil }
        argSVG = SVGUtilities.formalParentheses(argSVG)
        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .end, direction: .horizontal)
    }
    
    public init(_ params: [Node]) {
        self.argument = params[0]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
}

public struct Sin: Function {
    public let identifier: String = "sin"
    public let numArguments: Int = 1
    
    // Store the parameters for the node
    private var argument: Node
    
    public var symbol: Symbol? {
        return sin(self.argument.symbol)
    }
    
    public var description: String {
        return "sin(\(self.argument))"
    }
    
    public var latex: String {
        return "\\sin(\(self.argument.latex))"
    }
    
    public var formalSVG: SVGElement? {
        guard let nameSVG = SVGUtilities.svg(of: self.identifier) else { return nil }
        guard var argSVG = self.argument.formalSVG else { return nil }
        argSVG = SVGUtilities.formalParentheses(argSVG)
        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .end, direction: .horizontal)
    }
    
    public init(_ params: [Node]) {
        self.argument = params[0]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
}

public struct Cos: Function {
    public let identifier: String = "cos"
    public let numArguments: Int = 1
    
    // Store the parameters for the node
    private var argument: Node
    
    public var symbol: Symbol? {
        return cos(self.argument.symbol)
    }
    
    public var description: String {
        return "cos(\(self.argument))"
    }
    
    public var latex: String {
        return "\\cos(\(self.argument.latex))"
    }
    
    public var formalSVG: SVGElement? {
        guard let nameSVG = SVGUtilities.svg(of: self.identifier) else { return nil }
        guard var argSVG = self.argument.formalSVG else { return nil }
        argSVG = SVGUtilities.formalParentheses(argSVG)
        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .end, direction: .horizontal)
    }
    
    public init(_ params: [Node]) {
        self.argument = params[0]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
}

public struct Tan: Function {
    public let identifier: String = "tan"
    public let numArguments: Int = 1
    
    // Store the parameters for the node
    private var argument: Node
    
    public var symbol: Symbol? {
        return tan(self.argument.symbol)
    }
    
    public var description: String {
        return "tan(\(self.argument))"
    }
    
    public var latex: String {
        return "\\tan(\(self.argument.latex))"
    }
    
    public var formalSVG: SVGElement? {
        guard let nameSVG = SVGUtilities.svg(of: self.identifier) else { return nil }
        guard var argSVG = self.argument.formalSVG else { return nil }
        argSVG = SVGUtilities.formalParentheses(argSVG)
        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .end, direction: .horizontal)
    }
    
    public init(_ params: [Node]) {
        self.argument = params[0]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
}

public struct Asin: Function {
    public let identifier: String = "asin"
    public let numArguments: Int = 1
    
    // Store the parameters for the node
    private var argument: Node
    
    public var symbol: Symbol? {
        return asin(self.argument.symbol)
    }
    
    public var description: String {
        return "asin(\(self.argument))"
    }
    
    public var latex: String {
        return "\\arcsin(\(self.argument.latex))"
    }
    
    public var formalSVG: SVGElement? {
        guard let nameSVG = SVGUtilities.svg(of: self.identifier) else { return nil }
        guard var argSVG = self.argument.formalSVG else { return nil }
        argSVG = SVGUtilities.formalParentheses(argSVG)
        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .end, direction: .horizontal)
    }
    
    public init(_ params: [Node]) {
        self.argument = params[0]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
}

public struct Acos: Function {
    public let identifier: String = "acos"
    public let numArguments: Int = 1
    
    // Store the parameters for the node
    private var argument: Node
    
    public var symbol: Symbol? {
        return acos(self.argument.symbol)
    }
    
    public var description: String {
        return "acos(\(self.argument))"
    }
    
    public var latex: String {
        return "\\arccos(\(self.argument.latex))"
    }
    
    public var formalSVG: SVGElement? {
        guard let nameSVG = SVGUtilities.svg(of: self.identifier) else { return nil }
        guard var argSVG = self.argument.formalSVG else { return nil }
        argSVG = SVGUtilities.formalParentheses(argSVG)
        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .end, direction: .horizontal)
    }
    
    public init(_ params: [Node]) {
        self.argument = params[0]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
}

public struct Atan: Function {
    public let identifier: String = "atan"
    public let numArguments: Int = 1
    
    // Store the parameters for the node
    private var argument: Node
    
    public var symbol: Symbol? {
        return atan(self.argument.symbol)
    }
    
    public var description: String {
        return "atan(\(self.argument))"
    }
    
    public var latex: String {
        return "\\arctan(\(self.argument.latex))"
    }
    
    public var formalSVG: SVGElement? {
        guard let nameSVG = SVGUtilities.svg(of: self.identifier) else { return nil }
        guard var argSVG = self.argument.formalSVG else { return nil }
        argSVG = SVGUtilities.formalParentheses(argSVG)
        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .end, direction: .horizontal)
    }
    
    public init(_ params: [Node]) {
        self.argument = params[0]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
}

public struct Csc: Function {
    public let identifier: String = "csc"
    public let numArguments: Int = 1
    
    // Store the parameters for the node
    private var argument: Node
    
    public var symbol: Symbol? {
        return csc(self.argument.symbol)
    }
    
    public var description: String {
        return "csc(\(self.argument))"
    }
    
    public var latex: String {
        return "\\csc(\(self.argument.latex))"
    }
    
    public var formalSVG: SVGElement? {
        guard let nameSVG = SVGUtilities.svg(of: self.identifier) else { return nil }
        guard var argSVG = self.argument.formalSVG else { return nil }
        argSVG = SVGUtilities.formalParentheses(argSVG)
        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .end, direction: .horizontal)
    }
    
    public init(_ params: [Node]) {
        self.argument = params[0]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
}

public struct Sec: Function {
    public let identifier: String = "sec"
    public let numArguments: Int = 1
    
    // Store the parameters for the node
    private var argument: Node
    
    public var symbol: Symbol? {
        return sec(self.argument.symbol)
    }
    
    public var description: String {
        return "sec(\(self.argument))"
    }
    
    public var latex: String {
        return "\\sec(\(self.argument.latex))"
    }
    
    public var formalSVG: SVGElement? {
        guard let nameSVG = SVGUtilities.svg(of: self.identifier) else { return nil }
        guard var argSVG = self.argument.formalSVG else { return nil }
        argSVG = SVGUtilities.formalParentheses(argSVG)
        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .end, direction: .horizontal)
    }
    
    public init(_ params: [Node]) {
        self.argument = params[0]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
}

public struct Cot: Function {
    public let identifier: String = "cot"
    public let numArguments: Int = 1
    
    // Store the parameters for the node
    private var argument: Node
    
    public var symbol: Symbol? {
        return cot(self.argument.symbol)
    }
    
    public var description: String {
        return "cot(\(self.argument))"
    }
    
    public var latex: String {
        return "\\cot(\(self.argument.latex))"
    }
    
    public var formalSVG: SVGElement? {
        guard let nameSVG = SVGUtilities.svg(of: self.identifier) else { return nil }
        guard var argSVG = self.argument.formalSVG else { return nil }
        argSVG = SVGUtilities.formalParentheses(argSVG)
        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .end, direction: .horizontal)
    }
    
    public init(_ params: [Node]) {
        self.argument = params[0]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
}

public struct Acsc: Function {
    public let identifier: String = "acsc"
    public let numArguments: Int = 1
    
    // Store the parameters for the node
    private var argument: Node
    
    public var symbol: Symbol? {
        return acsc(self.argument.symbol)
    }
    
    public var description: String {
        return "acsc(\(self.argument))"
    }
    
    public var latex: String {
        return "\\textrm{arccsc}(\(self.argument.latex))"
    }
    
    public var formalSVG: SVGElement? {
        guard let nameSVG = SVGUtilities.svg(of: self.identifier) else { return nil }
        guard var argSVG = self.argument.formalSVG else { return nil }
        argSVG = SVGUtilities.formalParentheses(argSVG)
        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .end, direction: .horizontal)
    }
    
    public init(_ params: [Node]) {
        self.argument = params[0]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
}

public struct Asec: Function {
    public let identifier: String = "asec"
    public let numArguments: Int = 1
    
    // Store the parameters for the node
    private var argument: Node
    
    public var symbol: Symbol? {
        return asec(self.argument.symbol)
    }
    
    public var description: String {
        return "asec(\(self.argument))"
    }
    
    public var latex: String {
        return "\\textrm{arcsec}(\(self.argument.latex))"
    }
    
    public var formalSVG: SVGElement? {
        guard let nameSVG = SVGUtilities.svg(of: self.identifier) else { return nil }
        guard var argSVG = self.argument.formalSVG else { return nil }
        argSVG = SVGUtilities.formalParentheses(argSVG)
        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .end, direction: .horizontal)
    }
    
    public init(_ params: [Node]) {
        self.argument = params[0]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
}

public struct Acot: Function {
    public let identifier: String = "acot"
    public let numArguments: Int = 1
    
    // Store the parameters for the node
    private var argument: Node
    
    public var symbol: Symbol? {
        return acot(self.argument.symbol)
    }
    
    public var description: String {
        return "acot(\(self.argument))"
    }
    
    public var latex: String {
        return "\\textrm{arccot}(\(self.argument.latex))"
    }
    
    public var formalSVG: SVGElement? {
        guard let nameSVG = SVGUtilities.svg(of: self.identifier) else { return nil }
        guard var argSVG = self.argument.formalSVG else { return nil }
        argSVG = SVGUtilities.formalParentheses(argSVG)
        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .end, direction: .horizontal)
    }
    
    public init(_ params: [Node]) {
        self.argument = params[0]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
}

public struct Sinh: Function {
    public let identifier: String = "sinh"
    public let numArguments: Int = 1
    
    // Store the parameters for the node
    private var argument: Node
    
    public var symbol: Symbol? {
        return sinh(self.argument.symbol)
    }
    
    public var description: String {
        return "sinh(\(self.argument))"
    }
    
    public var latex: String {
        return "\\sinh(\(self.argument.latex))"
    }
    
    public var formalSVG: SVGElement? {
        guard let nameSVG = SVGUtilities.svg(of: self.identifier) else { return nil }
        guard var argSVG = self.argument.formalSVG else { return nil }
        argSVG = SVGUtilities.formalParentheses(argSVG)
        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .end, direction: .horizontal)
    }
    
    public init(_ params: [Node]) {
        self.argument = params[0]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
}

public struct Cosh: Function {
    public let identifier: String = "cosh"
    public let numArguments: Int = 1
    
    // Store the parameters for the node
    private var argument: Node
    
    public var symbol: Symbol? {
        return cosh(self.argument.symbol)
    }
    
    public var description: String {
        return "cosh(\(self.argument))"
    }
    
    public var latex: String {
        return "\\cosh(\(self.argument.latex))"
    }
    
    public var formalSVG: SVGElement? {
        guard let nameSVG = SVGUtilities.svg(of: self.identifier) else { return nil }
        guard var argSVG = self.argument.formalSVG else { return nil }
        argSVG = SVGUtilities.formalParentheses(argSVG)
        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .end, direction: .horizontal)
    }
    
    public init(_ params: [Node]) {
        self.argument = params[0]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
}

public struct Tanh: Function {
    public let identifier: String = "tanh"
    public let numArguments: Int = 1
    
    // Store the parameters for the node
    private var argument: Node
    
    public var symbol: Symbol? {
        return tanh(self.argument.symbol)
    }
    
    public var description: String {
        return "tanh(\(self.argument))"
    }
    
    public var latex: String {
        return "\\tanh(\(self.argument.latex))"
    }
    
    public var formalSVG: SVGElement? {
        guard let nameSVG = SVGUtilities.svg(of: self.identifier) else { return nil }
        guard var argSVG = self.argument.formalSVG else { return nil }
        argSVG = SVGUtilities.formalParentheses(argSVG)
        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .end, direction: .horizontal)
    }
    
    public init(_ params: [Node]) {
        self.argument = params[0]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
}

public struct Asinh: Function {
    public let identifier: String = "asinh"
    public let numArguments: Int = 1
    
    // Store the parameters for the node
    private var argument: Node
    
    public var symbol: Symbol? {
        return asinh(self.argument.symbol)
    }
    
    public var description: String {
        return "asinh(\(self.argument))"
    }
    
    public var latex: String {
        return "\\textrm{arcsinh}(\(self.argument.latex))"
    }
    
    public var formalSVG: SVGElement? {
        guard let nameSVG = SVGUtilities.svg(of: self.identifier) else { return nil }
        guard var argSVG = self.argument.formalSVG else { return nil }
        argSVG = SVGUtilities.formalParentheses(argSVG)
        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .end, direction: .horizontal)
    }
    
    public init(_ params: [Node]) {
        self.argument = params[0]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
}

public struct Acosh: Function {
    public let identifier: String = "acosh"
    public let numArguments: Int = 1
    
    // Store the parameters for the node
    private var argument: Node
    
    public var symbol: Symbol? {
        return acosh(self.argument.symbol)
    }
    
    public var description: String {
        return "acosh(\(self.argument))"
    }
    
    public var latex: String {
        return "\\textrm{arccosh}(\(self.argument.latex))"
    }
    
    public var formalSVG: SVGElement? {
        guard let nameSVG = SVGUtilities.svg(of: self.identifier) else { return nil }
        guard var argSVG = self.argument.formalSVG else { return nil }
        argSVG = SVGUtilities.formalParentheses(argSVG)
        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .end, direction: .horizontal)
    }
    
    public init(_ params: [Node]) {
        self.argument = params[0]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
}

public struct Atanh: Function {
    public let identifier: String = "atanh"
    public let numArguments: Int = 1
    
    // Store the parameters for the node
    private var argument: Node
    
    public var symbol: Symbol? {
        return atanh(self.argument.symbol)
    }
    
    public var description: String {
        return "atanh(\(self.argument))"
    }
    
    public var latex: String {
        return "\\textrm{arctanh}(\(self.argument.latex))"
    }
    
    public var formalSVG: SVGElement? {
        guard let nameSVG = SVGUtilities.svg(of: self.identifier) else { return nil }
        guard var argSVG = self.argument.formalSVG else { return nil }
        argSVG = SVGUtilities.formalParentheses(argSVG)
        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .end, direction: .horizontal)
    }
    
    public init(_ params: [Node]) {
        self.argument = params[0]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
}

public struct Csch: Function {
    public let identifier: String = "csch"
    public let numArguments: Int = 1
    
    // Store the parameters for the node
    private var argument: Node
    
    public var symbol: Symbol? {
        return csch(self.argument.symbol)
    }
    
    public var description: String {
        return "csch(\(self.argument))"
    }
    
    public var latex: String {
        return "\\textrm{csch}(\(self.argument.latex))"
    }
    
    public var formalSVG: SVGElement? {
        guard let nameSVG = SVGUtilities.svg(of: self.identifier) else { return nil }
        guard var argSVG = self.argument.formalSVG else { return nil }
        argSVG = SVGUtilities.formalParentheses(argSVG)
        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .end, direction: .horizontal)
    }
    
    public init(_ params: [Node]) {
        self.argument = params[0]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
}

public struct Sech: Function {
    public let identifier: String = "sech"
    public let numArguments: Int = 1
    
    // Store the parameters for the node
    private var argument: Node
    
    public var symbol: Symbol? {
        return sech(self.argument.symbol)
    }
    
    public var description: String {
        return "sech(\(self.argument))"
    }
    
    public var latex: String {
        return "\\textrm{sech}(\(self.argument.latex))"
    }
    
    public var formalSVG: SVGElement? {
        guard let nameSVG = SVGUtilities.svg(of: self.identifier) else { return nil }
        guard var argSVG = self.argument.formalSVG else { return nil }
        argSVG = SVGUtilities.formalParentheses(argSVG)
        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .end, direction: .horizontal)
    }
    
    public init(_ params: [Node]) {
        self.argument = params[0]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
}

public struct Coth: Function {
    public let identifier: String = "coth"
    public let numArguments: Int = 1
    
    // Store the parameters for the node
    private var argument: Node
    
    public var symbol: Symbol? {
        return coth(self.argument.symbol)
    }
    
    public var description: String {
        return "coth(\(self.argument))"
    }
    
    public var latex: String {
        return "\\textrm{coth}(\(self.argument.latex))"
    }
    
    public var formalSVG: SVGElement? {
        guard let nameSVG = SVGUtilities.svg(of: self.identifier) else { return nil }
        guard var argSVG = self.argument.formalSVG else { return nil }
        argSVG = SVGUtilities.formalParentheses(argSVG)
        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .end, direction: .horizontal)
    }
    
    public init(_ params: [Node]) {
        self.argument = params[0]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
}

public struct Acsch: Function {
    public let identifier: String = "acsch"
    public let numArguments: Int = 1
    
    // Store the parameters for the node
    private var argument: Node
    
    public var symbol: Symbol? {
        return acsch(self.argument.symbol)
    }
    
    public var description: String {
        return "acsch(\(self.argument))"
    }
    
    public var latex: String {
        return "\\textrm{arccsch}(\(self.argument.latex))"
    }
    
    public var formalSVG: SVGElement? {
        guard let nameSVG = SVGUtilities.svg(of: self.identifier) else { return nil }
        guard var argSVG = self.argument.formalSVG else { return nil }
        argSVG = SVGUtilities.formalParentheses(argSVG)
        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .end, direction: .horizontal)
    }
    
    public init(_ params: [Node]) {
        self.argument = params[0]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
}

public struct Asech: Function {
    public let identifier: String = "asech"
    public let numArguments: Int = 1
    
    // Store the parameters for the node
    private var argument: Node
    
    public var symbol: Symbol? {
        return asech(self.argument.symbol)
    }
    
    public var description: String {
        return "asech(\(self.argument))"
    }
    
    public var latex: String {
        return "\\textrm{arcsech}(\(self.argument.latex))"
    }
    
    public var formalSVG: SVGElement? {
        guard let nameSVG = SVGUtilities.svg(of: self.identifier) else { return nil }
        guard var argSVG = self.argument.formalSVG else { return nil }
        argSVG = SVGUtilities.formalParentheses(argSVG)
        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .end, direction: .horizontal)
    }
    
    public init(_ params: [Node]) {
        self.argument = params[0]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
}

public struct Acoth: Function {
    public let identifier: String = "acoth"
    public let numArguments: Int = 1
    
    // Store the parameters for the node
    private var argument: Node
    
    public var symbol: Symbol? {
        return acoth(self.argument.symbol)
    }
    
    public var description: String {
        return "acoth(\(self.argument))"
    }
    
    public var latex: String {
        return "\\textrm{arccoth}(\(self.argument.latex))"
    }
    
    public var formalSVG: SVGElement? {
        guard let nameSVG = SVGUtilities.svg(of: self.identifier) else { return nil }
        guard var argSVG = self.argument.formalSVG else { return nil }
        argSVG = SVGUtilities.formalParentheses(argSVG)
        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .end, direction: .horizontal)
    }
    
    public init(_ params: [Node]) {
        self.argument = params[0]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
}

public struct Sqrt: Function {
    public let identifier: String = "sqrt"
    public let numArguments: Int = 1
    
    // Store the parameters for the node
    private var argument: Node
    
    public var symbol: Symbol? {
        return sqrt(self.argument.symbol)
    }
    
    public var description: String {
        return "sqrt(\(self.argument))"
    }
    
    public var latex: String {
        return "\\sqrt{\(self.argument.latex)}"
    }
    
    public var formalSVG: SVGElement? {
        #warning("SQRT not really implemented")
        guard let nameSVG = SVGUtilities.svg(of: self.identifier) else { return nil }
        guard var argSVG = self.argument.formalSVG else { return nil }
        argSVG = SVGUtilities.formalParentheses(argSVG)
        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .end, direction: .horizontal)
    }
    
    public init(_ params: [Node]) {
        self.argument = params[0]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
}

public struct Exp: Function {
    public let identifier: String = "exp"
    public let numArguments: Int = 1
    
    // Store the parameters for the node
    private var argument: Node
    
    public var symbol: Symbol? {
        return exp(self.argument.symbol)
    }
    
    public var description: String {
        return "exp(\(self.argument))"
    }
    
    public var latex: String {
        return "e^{\(self.argument.latex)}"
    }
    
    public var formalSVG: SVGElement? {
        #warning("exponential not really implemented")
        guard let nameSVG = SVGUtilities.svg(of: self.identifier) else { return nil }
        guard var argSVG = self.argument.formalSVG else { return nil }
        argSVG = SVGUtilities.formalParentheses(argSVG)
        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .end, direction: .horizontal)
    }
    
    public init(_ params: [Node]) {
        self.argument = params[0]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
}

public struct Log: Function {
    public let identifier: String = "log"
    public let numArguments: Int = 1
    
    // Store the parameters for the node
    private var argument: Node
    
    public var symbol: Symbol? {
        return log(self.argument.symbol)
    }
    
    public var description: String {
        return "log(\(self.argument))"
    }
    
    public var latex: String {
        return "\\log(\(self.argument.latex))"
    }
    
    public var formalSVG: SVGElement? {
        guard let nameSVG = SVGUtilities.svg(of: self.identifier) else { return nil }
        guard var argSVG = self.argument.formalSVG else { return nil }
        argSVG = SVGUtilities.formalParentheses(argSVG)
        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .end, direction: .horizontal)
    }
    
    public init(_ params: [Node]) {
        self.argument = params[0]
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }
}
