//
//  File.swift
//  
//
//  Created by Ian Ruh on 5/15/20.
//

import RealModule

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
        OperationPrecedence(higherThan: Factorial().precedence)
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
public class Parentheses: Node, Function {
    // No identifier
    public let identifier: String = ""
    public let numArguments: Int = 1
    
    private var param: Node // Store the parameter for the node
    
    override public var description: String {
        return "(\(self.param))"
    }
    
    override public var latex: String {
        return "(\(self.param.latex))"
    }
    
    override public var variables: Set<String> {
        return self.param.variables
    }
    
    required public init(_ params: [Node]) {
        self.param = params[0]
    }

    override required public convenience init() {
        self.init([Node()])
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }

    override public func getSymbol<Engine:SymbolicMathEngine>(using type: Engine.Type) -> Engine.Symbol? {
        return self.param.getSymbol(using: type)
    }

    override public func generate(withOptions options: GeneratorOptions, depths: Depths = Depths()) -> Node {
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
    
    override public func svg(using source: SVGSource) -> SVGElement? {
        guard let argSVG = self.param.svg(using: source) else { return nil }
        return SVGUtilities.parentheses(argSVG, using: source)
    }
    
    override public func evaluate(withValues values: [String : Double]) throws -> Double {
        return try self.param.evaluate(withValues: values)
    }

    override public func contains<T: Node>(nodeType: T.Type) -> [Id] {
        var ids: [Id] = []
        if(nodeType == Parentheses.self) {
            ids.append(self.id)
        }
        ids.append(contentsOf: self.param.contains(nodeType: nodeType))
        return ids
    }

    public override func replace(id: Id, with replacement: Node) throws -> Bool {
        guard id != self.id else {
            throw SymbolLabError.cannotReplaceNode("because cannot replace self.")
        }

        // Replace children
        if(self.param.id == id) {
            self.param = replacement
            return true
        }

        // Recursively(ish) search children
        return try self.param.replace(id: id, with: replacement)
    }

    public override func getNode(withId id: Id) -> Node? {
        if(self.id == id) {
            return self
        }
        return self.param.getNode(withId: id)
    }
}

public class Derivative: Node, Function {
    public let identifier: String = "d"
    public let numArguments: Int = 2
    
    // Store the parameters for the node
    internal var diffOf: Node
    internal var withRespectTo: Node
    
    override public var description: String {
        return "d(\(self.diffOf),\(self.withRespectTo))"
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
        return "\\frac{d \(topStr)}{d \(bottomStr)}"
    }
    
    override public var variables: Set<String> {
        return self.diffOf.variables + self.withRespectTo.variables
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
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }

    override public func getSymbol<Engine:SymbolicMathEngine>(using type: Engine.Type) -> Engine.Symbol? {
        guard let of = self.diffOf.getSymbol(using: type) else {return nil}
        guard let v = self.withRespectTo.getSymbol(using: type) else {return nil}
        return Engine.diff(of: of, withRespectTo: v)
    }

    override public func generate(withOptions options: GeneratorOptions, depths: Depths = Depths()) -> Node {
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
    
    override public func svg(using source: SVGSource) -> SVGElement? {
        // TODO: SVG of derivative
        return nil
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
    override public func evaluate(withValues values: [String : Double]) throws -> Double {
        // Try symbolically
        // TODO: Symbolic derivative in evaluate
//        do {
//            guard let derSymbol: Symbol = self.symbol else {
//                throw SymbolLabError.misc("Couldn't get derivative symbol for '\(self.description)'")
//            }
//            guard let derNode = Parser().parse(cString: derSymbol.symbolLabString) else {
//                throw SymbolLabError.misc("Couldn't get derivative node for '\(derSymbol.description)'")
//            }
//
//            return try derNode.evaluate(withValues: values)
//        } catch {
//            #if DEBUG
//            print("""
//                  Could not evaluate derivative symbolically because:
//                  \(error)
//                  """)
//            #endif
//        }
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
        x_back[variable.description]! -= h
        var x_forward = values
        x_forward[variable.description]! += h

        return try (self.diffOf.evaluate(withValues: x_forward) - self.diffOf.evaluate(withValues: x_back)) / (2*h)
    }

    override public func contains<T: Node>(nodeType: T.Type) -> [Id] {
        var ids: [Id] = []
        if(nodeType == Derivative.self) {
            ids.append(self.id)
        }
        ids.append(contentsOf: self.withRespectTo.contains(nodeType: nodeType))
        ids.append(contentsOf: self.diffOf.contains(nodeType: nodeType))
        return ids
    }

    public override func replace(id: Id, with replacement: Node) throws -> Bool {
        guard id != self.id else {
            throw SymbolLabError.cannotReplaceNode("because cannot replace self.")
        }

        // Replace children
        if(self.diffOf.id == id) {
            self.diffOf = replacement
            return true
        } else if(self.withRespectTo.id == id) {
            self.withRespectTo = replacement
            return true
        }

        // Recursively(ish) search children
        return try self.diffOf.replace(id: id, with: replacement) || self.withRespectTo.replace(id: id, with: replacement)
    }

    public override func getNode(withId id: Id) -> Node? {
        if(self.id == id) {
            return self
        }

        if let node = self.diffOf.getNode(withId: id) {
            return node
        } else {
            return self.withRespectTo.getNode(withId: id)
        }
    }
}

public class Integral: Node, Function {
    public let identifier: String = "int"
    public let numArguments: Int = 4
    
    // Store the parameters for the node
    private var integrand: Node
    private var withRespectTo: Node
    private var lowerBound: Node
    private var upperBound: Node
    
    override public var description: String {
        return "int(\(self.integrand),\(self.withRespectTo),\(self.lowerBound),\(self.upperBound))"
    }
    
    override public var latex: String {
        let bottomStr = "\(self.lowerBound.latex)"
        let topStr = "\(self.upperBound.latex)"
        let integrandStr = "\(self.integrand.latex)"
        var withRespectToStr = "\(self.withRespectTo.latex)"
        if(!self.withRespectTo.isBasic) {
            withRespectToStr = "(\(withRespectToStr))"
        }
        
        return "\\int_{\(bottomStr)}^{\(topStr)} \(integrandStr) d\(withRespectToStr)"
    }
    
    override public var variables: Set<String> {
        return self.integrand.variables + self.withRespectTo.variables + self.lowerBound.variables + self.upperBound.variables
    }
    
    required public init(_ params: [Node]) {
        self.integrand = params[0]
        self.withRespectTo = params[1]
        self.lowerBound = params[2]
        self.upperBound = params[3]
    }

    override required public convenience init() {
        self.init([Node(), Node(), Node(), Node()])
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }

    override public func getSymbol<Engine:SymbolicMathEngine>(using type: Engine.Type) -> Engine.Symbol? {
        // TODO: Symbolic integration
        return nil
    }

    override public func svg(using source: SVGSource) -> SVGElement? {
        // TODO: SVG of integral
        return nil
    }
    
    override public func evaluate(withValues values: [String : Double]) throws -> Double {
        // TODO: Numerical integration
        throw SymbolLabError.notApplicable(message: "Can't evaluate integrals")
    }

    override public func contains<T: Node>(nodeType: T.Type) -> [Id] {
        var ids: [Id] = []
        if(nodeType == Integral.self) {
            ids.append(self.id)
        }
        ids.append(contentsOf: self.integrand.contains(nodeType: nodeType))
        ids.append(contentsOf: self.withRespectTo.contains(nodeType: nodeType))
        ids.append(contentsOf: self.lowerBound.contains(nodeType: nodeType))
        ids.append(contentsOf: self.upperBound.contains(nodeType: nodeType))
        return ids
    }

    public override func replace(id: Id, with replacement: Node) throws -> Bool {
        guard id != self.id else {
            throw SymbolLabError.cannotReplaceNode("because cannot replace self.")
        }

        // Replace children
        if(self.integrand.id == id) {
            self.integrand = replacement
            return true
        } else if(self.withRespectTo.id == id) {
            self.withRespectTo = replacement
            return true
        } else if(self.lowerBound.id == id) {
            self.lowerBound = replacement
            return true
        } else if(self.upperBound.id == id) {
            self.upperBound = replacement
            return true
        }

        // Recursively(ish) search children
        return try self.integrand.replace(id: id, with: replacement) ||
                self.withRespectTo.replace(id: id, with: replacement) ||
                self.lowerBound.replace(id: id, with: replacement) ||
                self.upperBound.replace(id: id, with: replacement)
    }

    public override func getNode(withId id: Id) -> Node? {
        if(self.id == id) {
            return self
        }
        if let node = self.integrand.getNode(withId: id) {
            return node
        } else if let node = self.withRespectTo.getNode(withId: id) {
            return node
        } else if let node = self.lowerBound.getNode(withId: id) {
            return node
        } else {
            return self.upperBound.getNode(withId: id)
        }
    }
}

public class Expand: Node, Function {
    public let identifier: String = "expand"
    public let numArguments: Int = 1
    
    // Store the parameters for the node
    private var argument: Node
    
    override public var description: String {
        return "expand(\(self.argument))"
    }
    
    // There is no equivalent of this as this isn't really mathematical
    override public var latex: String {
        return self.argument.latex
    }
    
    override public var variables: Set<String> {
        return self.argument.variables
    }
    
    required public init(_ params: [Node]) {
        self.argument = params[0]
    }

    override required public convenience init() {
        self.init([Node()])
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }

    override public func getSymbol<Engine:SymbolicMathEngine>(using type: Engine.Type) -> Engine.Symbol? {
        guard let param = self.argument.getSymbol(using: type) else {return nil}
        return Engine.expand(param)
    }

    override public func svg(using source: SVGSource) -> SVGElement? {
        guard let nameSVG = SVGUtilities.svg(of: self.identifier, using: source) else { return nil }
        guard var argSVG = self.argument.svg(using: source) else { return nil }
        argSVG = SVGUtilities.parentheses(argSVG, using: source)
        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .center, direction: .horizontal)
    }
    
    override public func evaluate(withValues values: [String : Double]) throws -> Double {
        return try self.argument.evaluate(withValues: values)
    }

    override public func contains<T: Node>(nodeType: T.Type) -> [Id] {
        var ids: [Id] = []
        if(nodeType == Expand.self) {
            ids.append(self.id)
        }
        ids.append(contentsOf: self.argument.contains(nodeType: nodeType))
        return ids
    }

    public override func replace(id: Id, with replacement: Node) throws -> Bool {
        guard id != self.id else {
            throw SymbolLabError.cannotReplaceNode("because cannot replace self.")
        }

        // Replace children
        if(self.argument.id == id) {
            self.argument = replacement
            return true
        }

        // Recursively(ish) search children
        return try self.argument.replace(id: id, with: replacement)
    }

    public override func getNode(withId id: Id) -> Node? {
        if(self.id == id) {
            return self
        }
        return self.argument.getNode(withId: id)
    }
}

public class AbsoluteValue: Node, Function {
    public let identifier: String = "abs"
    public let numArguments: Int = 1
    
    // Store the parameters for the node
    private var argument: Node
    
    override public var description: String {
        return "abs(\(self.argument))"
    }
    
    override public var latex: String {
        return "\\left| \(self.argument.latex) \\right|"
    }
    
    override public var variables: Set<String> {
        return self.argument.variables
    }
    
    required public init(_ params: [Node]) {
        self.argument = params[0]
    }

    override required public convenience init() {
        self.init([Node()])
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }

    override public func getSymbol<Engine:SymbolicMathEngine>(using type: Engine.Type) -> Engine.Symbol? {
        guard let param = self.argument.getSymbol(using: type) else {return nil}
        return Engine.abs(param)
    }

    override public func svg(using source: SVGSource) -> SVGElement? {
        guard let pipeSVG = source.getSymbol("|") else { return nil }
        guard let argSVG = self.argument.svg(using: source) else { return nil }
        let pipe2SVG = pipeSVG
        return SVGUtilities.compose(elements: [pipeSVG, argSVG, pipe2SVG], spacing: SVGOptions.parethesesSpacing, alignment: .center, direction: .horizontal)
    }
    
    override public func evaluate(withValues values: [String : Double]) throws -> Double {
        let val = try self.argument.evaluate(withValues: values)
        return val > 0 ? val: -1*val
    }

    override public func contains<T: Node>(nodeType: T.Type) -> [Id] {
        var ids: [Id] = []
        if(nodeType == AbsoluteValue.self) {
            ids.append(self.id)
        }
        ids.append(contentsOf: self.argument.contains(nodeType: nodeType))
        return ids
    }

    public override func replace(id: Id, with replacement: Node) throws -> Bool {
        guard id != self.id else {
            throw SymbolLabError.cannotReplaceNode("because cannot replace self.")
        }

        // Replace children
        if(self.argument.id == id) {
            self.argument = replacement
            return true
        }

        // Recursively(ish) search children
        return try self.argument.replace(id: id, with: replacement)
    }

    public override func getNode(withId id: Id) -> Node? {
        if(self.id == id) {
            return self
        }
        return self.argument.getNode(withId: id)
    }
}

public class ErrorFunction: Node, Function {
    public let identifier: String = "erf"
    public let numArguments: Int = 1
    
    // Store the parameters for the node
    private var argument: Node
    
    override public var description: String {
        return "erf(\(self.argument))"
    }
    
    override public var latex: String {
        return "\\textrm{erf}(\(self.argument.latex))"
    }
    
    override public var variables: Set<String> {
        return self.argument.variables
    }
    
    required public init(_ params: [Node]) {
        self.argument = params[0]
    }

    override required public convenience init() {
        self.init([Node()])
    }
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }

    override public func getSymbol<Engine:SymbolicMathEngine>(using type: Engine.Type) -> Engine.Symbol? {
        guard let param = self.argument.getSymbol(using: type) else {return nil}
        return Engine.erf(param)
    }

    override public func svg(using source: SVGSource) -> SVGElement? {
        guard let nameSVG = SVGUtilities.svg(of: self.identifier, using: source) else { return nil }
        guard var argSVG = self.argument.svg(using: source) else { return nil }
        argSVG = SVGUtilities.parentheses(argSVG, using: source)
        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .center, direction: .horizontal)
    }

    override public func evaluate(withValues values: [String: Double]) throws -> Double {
        throw SymbolLabError.notApplicable(message: "erf not implemneted yet")
    }

    override public func contains<T: Node>(nodeType: T.Type) -> [Id] {
        var ids: [Id] = []
        if(nodeType == ErrorFunction.self) {
            ids.append(self.id)
        }
        ids.append(contentsOf: self.argument.contains(nodeType: nodeType))
        return ids
    }

    public override func replace(id: Id, with replacement: Node) throws -> Bool {
        guard id != self.id else {
            throw SymbolLabError.cannotReplaceNode("because cannot replace self.")
        }

        // Replace children
        if(self.argument.id == id) {
            self.argument = replacement
            return true
        }

        // Recursively(ish) search children
        return try self.argument.replace(id: id, with: replacement)
    }

    public override func getNode(withId id: Id) -> Node? {
        if(self.id == id) {
            return self
        }
        return self.argument.getNode(withId: id)
    }
}

public class Sin: Node, Function {
    public let identifier: String = "sin"
    public let numArguments: Int = 1
    
    // Store the parameters for the node
    private var argument: Node
    
    override public var description: String {
        return "sin(\(self.argument))"
    }
    
    override public var latex: String {
        return "\\sin(\(self.argument.latex))"
    }
    
    override public var variables: Set<String> {
        return self.argument.variables
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
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }

    override public func getSymbol<Engine:SymbolicMathEngine>(using type: Engine.Type) -> Engine.Symbol? {
        guard let param = self.argument.getSymbol(using: type) else {return nil}
        return Engine.sin(param)
    }

    override public func svg(using source: SVGSource) -> SVGElement? {
        guard let nameSVG = SVGUtilities.svg(of: self.identifier, using: source) else { return nil }
        guard var argSVG = self.argument.svg(using: source) else { return nil }
        argSVG = SVGUtilities.parentheses(argSVG, using: source)
        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .center, direction: .horizontal)
    }

    override public func evaluate(withValues values: [String: Double]) throws -> Double {
        return try .sin(self.argument.evaluate(withValues: values))
    }

    override public func contains<T: Node>(nodeType: T.Type) -> [Id] {
        var ids: [Id] = []
        if(nodeType == Sin.self) {
            ids.append(self.id)
        }
        ids.append(contentsOf: self.argument.contains(nodeType: nodeType))
        return ids
    }

    public override func replace(id: Id, with replacement: Node) throws -> Bool {
        guard id != self.id else {
            throw SymbolLabError.cannotReplaceNode("because cannot replace self.")
        }

        // Replace children
        if(self.argument.id == id) {
            self.argument = replacement
            return true
        }

        // Recursively(ish) search children
        return try self.argument.replace(id: id, with: replacement)
    }

    public override func getNode(withId id: Id) -> Node? {
        if(self.id == id) {
            return self
        }
        return self.argument.getNode(withId: id)
    }
}

public class Cos: Node, Function {
    public let identifier: String = "cos"
    public let numArguments: Int = 1
    
    // Store the parameters for the node
    private var argument: Node
    
    override public var description: String {
        return "cos(\(self.argument))"
    }
    
    override public var latex: String {
        return "\\cos(\(self.argument.latex))"
    }
    
    override public var variables: Set<String> {
        return self.argument.variables
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
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }

    override public func getSymbol<Engine:SymbolicMathEngine>(using type: Engine.Type) -> Engine.Symbol? {
        guard let param = self.argument.getSymbol(using: type) else {return nil}
        return Engine.cos(param)
    }

    override public func svg(using source: SVGSource) -> SVGElement? {
        guard let nameSVG = SVGUtilities.svg(of: self.identifier, using: source) else { return nil }
        guard var argSVG = self.argument.svg(using: source) else { return nil }
        argSVG = SVGUtilities.parentheses(argSVG, using: source)
        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .center, direction: .horizontal)
    }

    override public func evaluate(withValues values: [String: Double]) throws -> Double {
        return try .cos(self.argument.evaluate(withValues: values))
    }

    override public func contains<T: Node>(nodeType: T.Type) -> [Id] {
        var ids: [Id] = []
        if(nodeType == Cos.self) {
            ids.append(self.id)
        }
        ids.append(contentsOf: self.argument.contains(nodeType: nodeType))
        return ids
    }

    public override func replace(id: Id, with replacement: Node) throws -> Bool {
        guard id != self.id else {
            throw SymbolLabError.cannotReplaceNode("because cannot replace self.")
        }

        // Replace children
        if(self.argument.id == id) {
            self.argument = replacement
            return true
        }

        // Recursively(ish) search children
        return try self.argument.replace(id: id, with: replacement)
    }

    public override func getNode(withId id: Id) -> Node? {
        if(self.id == id) {
            return self
        }
        return self.argument.getNode(withId: id)
    }
}

public class Tan: Node, Function {
    public let identifier: String = "tan"
    public let numArguments: Int = 1
    
    // Store the parameters for the node
    private var argument: Node
    
    override public var description: String {
        return "tan(\(self.argument))"
    }
    
    override public var latex: String {
        return "\\tan(\(self.argument.latex))"
    }
    
    override public var variables: Set<String> {
        return self.argument.variables
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
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }

    override public func getSymbol<Engine:SymbolicMathEngine>(using type: Engine.Type) -> Engine.Symbol? {
        guard let param = self.argument.getSymbol(using: type) else {return nil}
        return Engine.tan(param)
    }

    override public func svg(using source: SVGSource) -> SVGElement? {
        guard let nameSVG = SVGUtilities.svg(of: self.identifier, using: source) else { return nil }
        guard var argSVG = self.argument.svg(using: source) else { return nil }
        argSVG = SVGUtilities.parentheses(argSVG, using: source)
        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .center, direction: .horizontal)
    }

    override public func evaluate(withValues values: [String: Double]) throws -> Double {
        return try .tan(self.argument.evaluate(withValues: values))
    }

    override public func contains<T: Node>(nodeType: T.Type) -> [Id] {
        var ids: [Id] = []
        if(nodeType == Tan.self) {
            ids.append(self.id)
        }
        ids.append(contentsOf: self.argument.contains(nodeType: nodeType))
        return ids
    }

    public override func replace(id: Id, with replacement: Node) throws -> Bool {
        guard id != self.id else {
            throw SymbolLabError.cannotReplaceNode("because cannot replace self.")
        }

        // Replace children
        if(self.argument.id == id) {
            self.argument = replacement
            return true
        }

        // Recursively(ish) search children
        return try self.argument.replace(id: id, with: replacement)
    }

    public override func getNode(withId id: Id) -> Node? {
        if(self.id == id) {
            return self
        }
        return self.argument.getNode(withId: id)
    }
}

//public struct Asin: Function {
//    public let identifier: String = "asin"
//    public let numArguments: Int = 1
//
//    // Store the parameters for the node
//    private var argument: Node
//
//    public var symbol: Symbol? {
//        return asin(self.argument.symbol)
//    }
//
//    public var description: String {
//        return "asin(\(self.argument))"
//    }
//
//    public var latex: String {
//        return "\\arcsin(\(self.argument.latex))"
//    }
//
//    public var variables: Set<String> {
//        return self.argument.variables
//    }
//
//    public init(_ params: [Node]) {
//        self.argument = params[0]
//    }
//
//    public init(_ param: Node) {
//        self.init([param])
//    }
//
//    public func factory(_ params: [Node]) -> Node {
//        return Self(params)
//    }
//
//    public func svg(using source: SVGSource) -> SVGElement? {
//        guard let nameSVG = SVGUtilities.svg(of: self.identifier, using: source) else { return nil }
//        guard var argSVG = self.argument.svg(using: source) else { return nil }
//        argSVG = SVGUtilities.parentheses(argSVG, using: source)
//        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .center, direction: .horizontal)
//    }
//
//    public func evaluate(withValues values: [String: Double]) throws -> Double {
//        return try .asin(self.argument.evaluate(withValues: values))
//    }
//}
//
//public struct Acos: Function {
//    public let identifier: String = "acos"
//    public let numArguments: Int = 1
//
//    // Store the parameters for the node
//    private var argument: Node
//
//    public var symbol: Symbol? {
//        return acos(self.argument.symbol)
//    }
//
//    public var description: String {
//        return "acos(\(self.argument))"
//    }
//
//    public var latex: String {
//        return "\\arccos(\(self.argument.latex))"
//    }
//
//    public var variables: Set<String> {
//        return self.argument.variables
//    }
//
//    public init(_ params: [Node]) {
//        self.argument = params[0]
//    }
//
//    public init(_ param: Node) {
//        self.init([param])
//    }
//
//    public func factory(_ params: [Node]) -> Node {
//        return Self(params)
//    }
//
//    public func svg(using source: SVGSource) -> SVGElement? {
//        guard let nameSVG = SVGUtilities.svg(of: self.identifier, using: source) else { return nil }
//        guard var argSVG = self.argument.svg(using: source) else { return nil }
//        argSVG = SVGUtilities.parentheses(argSVG, using: source)
//        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .center, direction: .horizontal)
//    }
//
//    public func evaluate(withValues values: [String: Double]) throws -> Double {
//        return try .acos(self.argument.evaluate(withValues: values))
//    }
//}
//
//public struct Atan: Function {
//    public let identifier: String = "atan"
//    public let numArguments: Int = 1
//
//    // Store the parameters for the node
//    private var argument: Node
//
//    public var symbol: Symbol? {
//        return atan(self.argument.symbol)
//    }
//
//    public var description: String {
//        return "atan(\(self.argument))"
//    }
//
//    public var latex: String {
//        return "\\arctan(\(self.argument.latex))"
//    }
//
//    public var variables: Set<String> {
//        return self.argument.variables
//    }
//
//    public init(_ params: [Node]) {
//        self.argument = params[0]
//    }
//
//    public init(_ param: Node) {
//        self.init([param])
//    }
//
//    public func factory(_ params: [Node]) -> Node {
//        return Self(params)
//    }
//
//    public func svg(using source: SVGSource) -> SVGElement? {
//        guard let nameSVG = SVGUtilities.svg(of: self.identifier, using: source) else { return nil }
//        guard var argSVG = self.argument.svg(using: source) else { return nil }
//        argSVG = SVGUtilities.parentheses(argSVG, using: source)
//        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .center, direction: .horizontal)
//    }
//
//    public func evaluate(withValues values: [String: Double]) throws -> Double {
//        return try .atan(self.argument.evaluate(withValues: values))
//    }
//}
//
//public struct Csc: Function {
//    public let identifier: String = "csc"
//    public let numArguments: Int = 1
//
//    // Store the parameters for the node
//    private var argument: Node
//
//    public var symbol: Symbol? {
//        return csc(self.argument.symbol)
//    }
//
//    public var description: String {
//        return "csc(\(self.argument))"
//    }
//
//    public var latex: String {
//        return "\\csc(\(self.argument.latex))"
//    }
//
//    public var variables: Set<String> {
//        return self.argument.variables
//    }
//
//    public init(_ params: [Node]) {
//        self.argument = params[0]
//    }
//
//    public init(_ param: Node) {
//        self.init([param])
//    }
//
//    public func factory(_ params: [Node]) -> Node {
//        return Self(params)
//    }
//
//    public func svg(using source: SVGSource) -> SVGElement? {
//        guard let nameSVG = SVGUtilities.svg(of: self.identifier, using: source) else { return nil }
//        guard var argSVG = self.argument.svg(using: source) else { return nil }
//        argSVG = SVGUtilities.parentheses(argSVG, using: source)
//        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .center, direction: .horizontal)
//    }
//
//    public func evaluate(withValues values: [String: Double]) throws -> Double {
//        return try 1 / .sin(self.argument.evaluate(withValues: values))
//    }
//}
//
//public struct Sec: Function {
//    public let identifier: String = "sec"
//    public let numArguments: Int = 1
//
//    // Store the parameters for the node
//    private var argument: Node
//
//    public var symbol: Symbol? {
//        return sec(self.argument.symbol)
//    }
//
//    public var description: String {
//        return "sec(\(self.argument))"
//    }
//
//    public var latex: String {
//        return "\\sec(\(self.argument.latex))"
//    }
//
//    public var variables: Set<String> {
//        return self.argument.variables
//    }
//
//    public init(_ params: [Node]) {
//        self.argument = params[0]
//    }
//
//    public init(_ param: Node) {
//        self.init([param])
//    }
//
//    public func factory(_ params: [Node]) -> Node {
//        return Self(params)
//    }
//
//    public func svg(using source: SVGSource) -> SVGElement? {
//        guard let nameSVG = SVGUtilities.svg(of: self.identifier, using: source) else { return nil }
//        guard var argSVG = self.argument.svg(using: source) else { return nil }
//        argSVG = SVGUtilities.parentheses(argSVG, using: source)
//        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .center, direction: .horizontal)
//    }
//
//    public func evaluate(withValues values: [String: Double]) throws -> Double {
//        return try 1  / .cos(self.argument.evaluate(withValues: values))
//    }
//}
//
//public struct Cot: Function {
//    public let identifier: String = "cot"
//    public let numArguments: Int = 1
//
//    // Store the parameters for the node
//    private var argument: Node
//
//    public var symbol: Symbol? {
//        return cot(self.argument.symbol)
//    }
//
//    public var description: String {
//        return "cot(\(self.argument))"
//    }
//
//    public var latex: String {
//        return "\\cot(\(self.argument.latex))"
//    }
//
//    public var variables: Set<String> {
//        return self.argument.variables
//    }
//
//    public init(_ params: [Node]) {
//        self.argument = params[0]
//    }
//
//    public init(_ param: Node) {
//        self.init([param])
//    }
//
//    public func factory(_ params: [Node]) -> Node {
//        return Self(params)
//    }
//
//    public func svg(using source: SVGSource) -> SVGElement? {
//        guard let nameSVG = SVGUtilities.svg(of: self.identifier, using: source) else { return nil }
//        guard var argSVG = self.argument.svg(using: source) else { return nil }
//        argSVG = SVGUtilities.parentheses(argSVG, using: source)
//        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .center, direction: .horizontal)
//    }
//
//    public func evaluate(withValues values: [String: Double]) throws -> Double {
//        return try 1 / .tan(self.argument.evaluate(withValues: values))
//    }
//}
//
//public struct Acsc: Function {
//    public let identifier: String = "acsc"
//    public let numArguments: Int = 1
//
//    // Store the parameters for the node
//    private var argument: Node
//
//    public var symbol: Symbol? {
//        return acsc(self.argument.symbol)
//    }
//
//    public var description: String {
//        return "acsc(\(self.argument))"
//    }
//
//    public var latex: String {
//        return "\\textrm{arccsc}(\(self.argument.latex))"
//    }
//
//    public var variables: Set<String> {
//        return self.argument.variables
//    }
//
//    public init(_ params: [Node]) {
//        self.argument = params[0]
//    }
//
//    public init(_ param: Node) {
//        self.init([param])
//    }
//
//    public func factory(_ params: [Node]) -> Node {
//        return Self(params)
//    }
//
//    public func svg(using source: SVGSource) -> SVGElement? {
//        guard let nameSVG = SVGUtilities.svg(of: self.identifier, using: source) else { return nil }
//        guard var argSVG = self.argument.svg(using: source) else { return nil }
//        argSVG = SVGUtilities.parentheses(argSVG, using: source)
//        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .center, direction: .horizontal)
//    }
//
//    public func evaluate(withValues values: [String: Double]) throws -> Double {
//        return try .asin(1 / self.argument.evaluate(withValues: values))
//    }
//}
//
//public struct Asec: Function {
//    public let identifier: String = "asec"
//    public let numArguments: Int = 1
//
//    // Store the parameters for the node
//    private var argument: Node
//
//    public var symbol: Symbol? {
//        return asec(self.argument.symbol)
//    }
//
//    public var description: String {
//        return "asec(\(self.argument))"
//    }
//
//    public var latex: String {
//        return "\\textrm{arcsec}(\(self.argument.latex))"
//    }
//
//    public var variables: Set<String> {
//        return self.argument.variables
//    }
//
//    public init(_ params: [Node]) {
//        self.argument = params[0]
//    }
//
//    public init(_ param: Node) {
//        self.init([param])
//    }
//
//    public func factory(_ params: [Node]) -> Node {
//        return Self(params)
//    }
//
//    public func svg(using source: SVGSource) -> SVGElement? {
//        guard let nameSVG = SVGUtilities.svg(of: self.identifier, using: source) else { return nil }
//        guard var argSVG = self.argument.svg(using: source) else { return nil }
//        argSVG = SVGUtilities.parentheses(argSVG, using: source)
//        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .center, direction: .horizontal)
//    }
//
//    public func evaluate(withValues values: [String: Double]) throws -> Double {
//        return try .acos(1 / self.argument.evaluate(withValues: values))
//    }
//}
//
//public struct Acot: Function {
//    public let identifier: String = "acot"
//    public let numArguments: Int = 1
//
//    // Store the parameters for the node
//    private var argument: Node
//
//    public var symbol: Symbol? {
//        return acot(self.argument.symbol)
//    }
//
//    public var description: String {
//        return "acot(\(self.argument))"
//    }
//
//    public var latex: String {
//        return "\\textrm{arccot}(\(self.argument.latex))"
//    }
//
//    public var variables: Set<String> {
//        return self.argument.variables
//    }
//
//    public init(_ params: [Node]) {
//        self.argument = params[0]
//    }
//
//    public init(_ param: Node) {
//        self.init([param])
//    }
//
//    public func factory(_ params: [Node]) -> Node {
//        return Self(params)
//    }
//
//    public func svg(using source: SVGSource) -> SVGElement? {
//        guard let nameSVG = SVGUtilities.svg(of: self.identifier, using: source) else { return nil }
//        guard var argSVG = self.argument.svg(using: source) else { return nil }
//        argSVG = SVGUtilities.parentheses(argSVG, using: source)
//        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .center, direction: .horizontal)
//    }
//
//    public func evaluate(withValues values: [String: Double]) throws -> Double {
//        throw SymbolLabError.notApplicable(message: "arccotan is too hard. me done.")
//    }
//}
//
//public struct Sinh: Function {
//    public let identifier: String = "sinh"
//    public let numArguments: Int = 1
//
//    // Store the parameters for the node
//    private var argument: Node
//
//    public var symbol: Symbol? {
//        return sinh(self.argument.symbol)
//    }
//
//    public var description: String {
//        return "sinh(\(self.argument))"
//    }
//
//    public var latex: String {
//        return "\\sinh(\(self.argument.latex))"
//    }
//
//    public var variables: Set<String> {
//        return self.argument.variables
//    }
//
//    public init(_ params: [Node]) {
//        self.argument = params[0]
//    }
//
//    public init(_ param: Node) {
//        self.init([param])
//    }
//
//    public func factory(_ params: [Node]) -> Node {
//        return Self(params)
//    }
//
//    public func svg(using source: SVGSource) -> SVGElement? {
//        guard let nameSVG = SVGUtilities.svg(of: self.identifier, using: source) else { return nil }
//        guard var argSVG = self.argument.svg(using: source) else { return nil }
//        argSVG = SVGUtilities.parentheses(argSVG, using: source)
//        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .center, direction: .horizontal)
//    }
//
//    public func evaluate(withValues values: [String: Double]) throws -> Double {
//        return try .sinh(self.argument.evaluate(withValues: values))
//    }
//}
//
//public struct Cosh: Function {
//    public let identifier: String = "cosh"
//    public let numArguments: Int = 1
//
//    // Store the parameters for the node
//    private var argument: Node
//
//    public var symbol: Symbol? {
//        return cosh(self.argument.symbol)
//    }
//
//    public var description: String {
//        return "cosh(\(self.argument))"
//    }
//
//    public var latex: String {
//        return "\\cosh(\(self.argument.latex))"
//    }
//
//    public var variables: Set<String> {
//        return self.argument.variables
//    }
//
//    public init(_ params: [Node]) {
//        self.argument = params[0]
//    }
//
//    public init(_ param: Node) {
//        self.init([param])
//    }
//
//    public func factory(_ params: [Node]) -> Node {
//        return Self(params)
//    }
//
//    public func svg(using source: SVGSource) -> SVGElement? {
//        guard let nameSVG = SVGUtilities.svg(of: self.identifier, using: source) else { return nil }
//        guard var argSVG = self.argument.svg(using: source) else { return nil }
//        argSVG = SVGUtilities.parentheses(argSVG, using: source)
//        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .center, direction: .horizontal)
//    }
//
//    public func evaluate(withValues values: [String: Double]) throws -> Double {
//        return try .cosh(self.argument.evaluate(withValues: values))
//    }
//}
//
//public struct Tanh: Function {
//    public let identifier: String = "tanh"
//    public let numArguments: Int = 1
//
//    // Store the parameters for the node
//    private var argument: Node
//
//    public var symbol: Symbol? {
//        return tanh(self.argument.symbol)
//    }
//
//    public var description: String {
//        return "tanh(\(self.argument))"
//    }
//
//    public var latex: String {
//        return "\\tanh(\(self.argument.latex))"
//    }
//
//    public var variables: Set<String> {
//        return self.argument.variables
//    }
//
//    public init(_ params: [Node]) {
//        self.argument = params[0]
//    }
//
//    public init(_ param: Node) {
//        self.init([param])
//    }
//
//    public func factory(_ params: [Node]) -> Node {
//        return Self(params)
//    }
//
//    public func svg(using source: SVGSource) -> SVGElement? {
//        guard let nameSVG = SVGUtilities.svg(of: self.identifier, using: source) else { return nil }
//        guard var argSVG = self.argument.svg(using: source) else { return nil }
//        argSVG = SVGUtilities.parentheses(argSVG, using: source)
//        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .center, direction: .horizontal)
//    }
//
//    public func evaluate(withValues values: [String: Double]) throws -> Double {
//        return try .tanh(self.argument.evaluate(withValues: values))
//    }
//}
//
//public struct Asinh: Function {
//    public let identifier: String = "asinh"
//    public let numArguments: Int = 1
//
//    // Store the parameters for the node
//    private var argument: Node
//
//    public var symbol: Symbol? {
//        return asinh(self.argument.symbol)
//    }
//
//    public var description: String {
//        return "asinh(\(self.argument))"
//    }
//
//    public var latex: String {
//        return "\\textrm{arcsinh}(\(self.argument.latex))"
//    }
//
//    public var variables: Set<String> {
//        return self.argument.variables
//    }
//
//    public init(_ params: [Node]) {
//        self.argument = params[0]
//    }
//
//    public init(_ param: Node) {
//        self.init([param])
//    }
//
//    public func factory(_ params: [Node]) -> Node {
//        return Self(params)
//    }
//
//    public func svg(using source: SVGSource) -> SVGElement? {
//        guard let nameSVG = SVGUtilities.svg(of: self.identifier, using: source) else { return nil }
//        guard var argSVG = self.argument.svg(using: source) else { return nil }
//        argSVG = SVGUtilities.parentheses(argSVG, using: source)
//        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .center, direction: .horizontal)
//    }
//
//    public func evaluate(withValues values: [String: Double]) throws -> Double {
//        return try .asinh(self.argument.evaluate(withValues: values))
//    }
//}
//
//public struct Acosh: Function {
//    public let identifier: String = "acosh"
//    public let numArguments: Int = 1
//
//    // Store the parameters for the node
//    private var argument: Node
//
//    public var symbol: Symbol? {
//        return acosh(self.argument.symbol)
//    }
//
//    public var description: String {
//        return "acosh(\(self.argument))"
//    }
//
//    public var latex: String {
//        return "\\textrm{arccosh}(\(self.argument.latex))"
//    }
//
//    public var variables: Set<String> {
//        return self.argument.variables
//    }
//
//    public init(_ params: [Node]) {
//        self.argument = params[0]
//    }
//
//    public init(_ param: Node) {
//        self.init([param])
//    }
//
//    public func factory(_ params: [Node]) -> Node {
//        return Self(params)
//    }
//
//    public func svg(using source: SVGSource) -> SVGElement? {
//        guard let nameSVG = SVGUtilities.svg(of: self.identifier, using: source) else { return nil }
//        guard var argSVG = self.argument.svg(using: source) else { return nil }
//        argSVG = SVGUtilities.parentheses(argSVG, using: source)
//        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .center, direction: .horizontal)
//    }
//
//    public func evaluate(withValues values: [String: Double]) throws -> Double {
//        return try .acosh(self.argument.evaluate(withValues: values))
//    }
//}
//
//public struct Atanh: Function {
//    public let identifier: String = "atanh"
//    public let numArguments: Int = 1
//
//    // Store the parameters for the node
//    private var argument: Node
//
//    public var symbol: Symbol? {
//        return atanh(self.argument.symbol)
//    }
//
//    public var description: String {
//        return "atanh(\(self.argument))"
//    }
//
//    public var latex: String {
//        return "\\textrm{arctanh}(\(self.argument.latex))"
//    }
//
//    public var variables: Set<String> {
//        return self.argument.variables
//    }
//
//    public init(_ params: [Node]) {
//        self.argument = params[0]
//    }
//
//    public init(_ param: Node) {
//        self.init([param])
//    }
//
//    public func factory(_ params: [Node]) -> Node {
//        return Self(params)
//    }
//
//    public func svg(using source: SVGSource) -> SVGElement? {
//        guard let nameSVG = SVGUtilities.svg(of: self.identifier, using: source) else { return nil }
//        guard var argSVG = self.argument.svg(using: source) else { return nil }
//        argSVG = SVGUtilities.parentheses(argSVG, using: source)
//        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .center, direction: .horizontal)
//    }
//
//    public func evaluate(withValues values: [String: Double]) throws -> Double {
//        return try .atanh(self.argument.evaluate(withValues: values))
//    }
//}
//
//public struct Csch: Function {
//    public let identifier: String = "csch"
//    public let numArguments: Int = 1
//
//    // Store the parameters for the node
//    private var argument: Node
//
//    public var symbol: Symbol? {
//        return csch(self.argument.symbol)
//    }
//
//    public var description: String {
//        return "csch(\(self.argument))"
//    }
//
//    public var latex: String {
//        return "\\textrm{csch}(\(self.argument.latex))"
//    }
//
//    public var variables: Set<String> {
//        return self.argument.variables
//    }
//
//    public init(_ params: [Node]) {
//        self.argument = params[0]
//    }
//
//    public init(_ param: Node) {
//        self.init([param])
//    }
//
//    public func factory(_ params: [Node]) -> Node {
//        return Self(params)
//    }
//
//    public func svg(using source: SVGSource) -> SVGElement? {
//        guard let nameSVG = SVGUtilities.svg(of: self.identifier, using: source) else { return nil }
//        guard var argSVG = self.argument.svg(using: source) else { return nil }
//        argSVG = SVGUtilities.parentheses(argSVG, using: source)
//        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .center, direction: .horizontal)
//    }
//
//    public func evaluate(withValues values: [String: Double]) throws -> Double {
//        throw SymbolLabError.notApplicable(message: "IDK acsch")
//    }
//}
//
//public struct Sech: Function {
//    public let identifier: String = "sech"
//    public let numArguments: Int = 1
//
//    // Store the parameters for the node
//    private var argument: Node
//
//    public var symbol: Symbol? {
//        return sech(self.argument.symbol)
//    }
//
//    public var description: String {
//        return "sech(\(self.argument))"
//    }
//
//    public var latex: String {
//        return "\\textrm{sech}(\(self.argument.latex))"
//    }
//
//    public var variables: Set<String> {
//        return self.argument.variables
//    }
//
//    public init(_ params: [Node]) {
//        self.argument = params[0]
//    }
//
//    public init(_ param: Node) {
//        self.init([param])
//    }
//
//    public func factory(_ params: [Node]) -> Node {
//        return Self(params)
//    }
//
//    public func svg(using source: SVGSource) -> SVGElement? {
//        guard let nameSVG = SVGUtilities.svg(of: self.identifier, using: source) else { return nil }
//        guard var argSVG = self.argument.svg(using: source) else { return nil }
//        argSVG = SVGUtilities.parentheses(argSVG, using: source)
//        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .center, direction: .horizontal)
//    }
//
//    public func evaluate(withValues values: [String: Double]) throws -> Double {
//        throw SymbolLabError.notApplicable(message: "IDK asech")
//    }
//}
//
//public struct Coth: Function {
//    public let identifier: String = "coth"
//    public let numArguments: Int = 1
//
//    // Store the parameters for the node
//    private var argument: Node
//
//    public var symbol: Symbol? {
//        return coth(self.argument.symbol)
//    }
//
//    public var description: String {
//        return "coth(\(self.argument))"
//    }
//
//    public var latex: String {
//        return "\\textrm{coth}(\(self.argument.latex))"
//    }
//
//    public var variables: Set<String> {
//        return self.argument.variables
//    }
//
//    public init(_ params: [Node]) {
//        self.argument = params[0]
//    }
//
//    public init(_ param: Node) {
//        self.init([param])
//    }
//
//    public func factory(_ params: [Node]) -> Node {
//        return Self(params)
//    }
//
//    public func svg(using source: SVGSource) -> SVGElement? {
//        guard let nameSVG = SVGUtilities.svg(of: self.identifier, using: source) else { return nil }
//        guard var argSVG = self.argument.svg(using: source) else { return nil }
//        argSVG = SVGUtilities.parentheses(argSVG, using: source)
//        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .center, direction: .horizontal)
//    }
//
//    public func evaluate(withValues values: [String: Double]) throws -> Double {
//        throw SymbolLabError.notApplicable(message: "IDK acot")
//    }
//}
//
//public struct Acsch: Function {
//    public let identifier: String = "acsch"
//    public let numArguments: Int = 1
//
//    // Store the parameters for the node
//    private var argument: Node
//
//    public var symbol: Symbol? {
//        return acsch(self.argument.symbol)
//    }
//
//    public var description: String {
//        return "acsch(\(self.argument))"
//    }
//
//    public var latex: String {
//        return "\\textrm{arccsch}(\(self.argument.latex))"
//    }
//
//    public var variables: Set<String> {
//        return self.argument.variables
//    }
//
//    public init(_ params: [Node]) {
//        self.argument = params[0]
//    }
//
//    public init(_ param: Node) {
//        self.init([param])
//    }
//
//    public func factory(_ params: [Node]) -> Node {
//        return Self(params)
//    }
//
//    public func svg(using source: SVGSource) -> SVGElement? {
//        guard let nameSVG = SVGUtilities.svg(of: self.identifier, using: source) else { return nil }
//        guard var argSVG = self.argument.svg(using: source) else { return nil }
//        argSVG = SVGUtilities.parentheses(argSVG, using: source)
//        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .center, direction: .horizontal)
//    }
//
//    public func evaluate(withValues values: [String: Double]) throws -> Double {
//        throw SymbolLabError.notApplicable(message: "IDK acsch")
//    }
//}
//
//public struct Asech: Function {
//    public let identifier: String = "asech"
//    public let numArguments: Int = 1
//
//    // Store the parameters for the node
//    private var argument: Node
//
//    public var symbol: Symbol? {
//        return asech(self.argument.symbol)
//    }
//
//    public var description: String {
//        return "asech(\(self.argument))"
//    }
//
//    public var latex: String {
//        return "\\textrm{arcsech}(\(self.argument.latex))"
//    }
//
//    public var variables: Set<String> {
//        return self.argument.variables
//    }
//
//    public init(_ params: [Node]) {
//        self.argument = params[0]
//    }
//
//    public init(_ param: Node) {
//        self.init([param])
//    }
//
//    public func factory(_ params: [Node]) -> Node {
//        return Self(params)
//    }
//
//    public func svg(using source: SVGSource) -> SVGElement? {
//        guard let nameSVG = SVGUtilities.svg(of: self.identifier, using: source) else { return nil }
//        guard var argSVG = self.argument.svg(using: source) else { return nil }
//        argSVG = SVGUtilities.parentheses(argSVG, using: source)
//        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .center, direction: .horizontal)
//    }
//
//    public func evaluate(withValues values: [String: Double]) throws -> Double {
//        throw SymbolLabError.notApplicable(message: "IDK asech")
//    }
//}
//
//public struct Acoth: Function {
//    public let identifier: String = "acoth"
//    public let numArguments: Int = 1
//
//    // Store the parameters for the node
//    private var argument: Node
//
//    public var symbol: Symbol? {
//        return acoth(self.argument.symbol)
//    }
//
//    public var description: String {
//        return "acoth(\(self.argument))"
//    }
//
//    public var latex: String {
//        return "\\textrm{arccoth}(\(self.argument.latex))"
//    }
//
//    public var variables: Set<String> {
//        return self.argument.variables
//    }
//
//    public init(_ params: [Node]) {
//        self.argument = params[0]
//    }
//
//    public init(_ param: Node) {
//        self.init([param])
//    }
//
//    public func factory(_ params: [Node]) -> Node {
//        return Self(params)
//    }
//
//    public func svg(using source: SVGSource) -> SVGElement? {
//        guard let nameSVG = SVGUtilities.svg(of: self.identifier, using: source) else { return nil }
//        guard var argSVG = self.argument.svg(using: source) else { return nil }
//        argSVG = SVGUtilities.parentheses(argSVG, using: source)
//        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .center, direction: .horizontal)
//    }
//
//    public func evaluate(withValues values: [String: Double]) throws -> Double {
//        throw SymbolLabError.notApplicable(message: "IDK acoth")
//    }
//}

public class Sqrt: Node, Function {
    public let identifier: String = "sqrt"
    public let numArguments: Int = 1
    
    // Store the parameters for the node
    private var argument: Node
    
    override public var description: String {
        return "sqrt(\(self.argument))"
    }
    
    override public var latex: String {
        return "\\sqrt{\(self.argument.latex)}"
    }
    
    override public var variables: Set<String> {
        return self.argument.variables
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
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }

    override public func getSymbol<Engine:SymbolicMathEngine>(using type: Engine.Type) -> Engine.Symbol? {
        guard let param  = self.argument.getSymbol(using: type) else {return nil}
        return Engine.sqrt(param)
    }

    override public func svg(using source: SVGSource) -> SVGElement? {
        // TODO: Actual sqrt symbol for svg
        guard let nameSVG = SVGUtilities.svg(of: self.identifier, using: source) else { return nil }
        guard var argSVG = self.argument.svg(using: source) else { return nil }
        argSVG = SVGUtilities.parentheses(argSVG, using: source)
        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .center, direction: .horizontal)
    }

    override public func evaluate(withValues values: [String: Double]) throws -> Double {
        return try .sqrt(self.argument.evaluate(withValues: values))
    }

    override public func contains<T: Node>(nodeType: T.Type) -> [Id] {
        var ids: [Id] = []
        if(nodeType == Sqrt.self) {
            ids.append(self.id)
        }
        ids.append(contentsOf: self.argument.contains(nodeType: nodeType))
        return ids
    }

    public override func replace(id: Id, with replacement: Node) throws -> Bool {
        guard id != self.id else {
            throw SymbolLabError.cannotReplaceNode("because cannot replace self.")
        }

        // Replace children
        if(self.argument.id == id) {
            self.argument = replacement
            return true
        }

        // Recursively(ish) search children
        return try self.argument.replace(id: id, with: replacement)
    }

    public override func getNode(withId id: Id) -> Node? {
        if(self.id == id) {
            return self
        }
        return self.argument.getNode(withId: id)
    }
}

public class Exp: Node, Function {
    public let identifier: String = "exp"
    public let numArguments: Int = 1
    
    // Store the parameters for the node
    private var argument: Node
    
    override public var description: String {
        return "exp(\(self.argument))"
    }
    
    override public var latex: String {
        return "e^{\(self.argument.latex)}"
    }
    
    override public var variables: Set<String> {
        return self.argument.variables
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
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }

    override public func getSymbol<Engine:SymbolicMathEngine>(using type: Engine.Type) -> Engine.Symbol? {
        guard let param = self.argument.getSymbol(using: type) else {return nil}
        return Engine.exp(param)
    }

    override public func svg(using source: SVGSource) -> SVGElement? {
        // TODO: Actual exp svg
        guard let nameSVG = SVGUtilities.svg(of: self.identifier, using: source) else { return nil }
        guard var argSVG = self.argument.svg(using: source) else { return nil }
        argSVG = SVGUtilities.parentheses(argSVG, using: source)
        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .center, direction: .horizontal)
    }

    override public func evaluate(withValues values: [String: Double]) throws -> Double {
        return try  .exp(self.argument.evaluate(withValues: values))
    }

    override public func contains<T: Node>(nodeType: T.Type) -> [Id] {
        var ids: [Id] = []
        if(nodeType == Exp.self) {
            ids.append(self.id)
        }
        ids.append(contentsOf: self.argument.contains(nodeType: nodeType))
        return ids
    }

    public override func replace(id: Id, with replacement: Node) throws -> Bool {
        guard id != self.id else {
            throw SymbolLabError.cannotReplaceNode("because cannot replace self.")
        }

        // Replace children
        if(self.argument.id == id) {
            self.argument = replacement
            return true
        }

        // Recursively(ish) search children
        return try self.argument.replace(id: id, with: replacement)
    }

    public override func getNode(withId id: Id) -> Node? {
        if(self.id == id) {
            return self
        }
        return self.argument.getNode(withId: id)
    }
}

public class Log: Node, Function {
    public let identifier: String = "log"
    public let numArguments: Int = 1
    
    // Store the parameters for the node
    private var argument: Node
    
    override public var description: String {
        return "log(\(self.argument))"
    }
    
    override public var latex: String {
        return "\\log(\(self.argument.latex))"
    }
    
    override public var variables: Set<String> {
        return self.argument.variables
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
    
    public func factory(_ params: [Node]) -> Node {
        return Self(params)
    }

    override public func getSymbol<Engine:SymbolicMathEngine>(using type: Engine.Type) -> Engine.Symbol? {
        guard let param = self.argument.getSymbol(using: type) else {return nil}
        return Engine.log(param)
    }

    override public func svg(using source: SVGSource) -> SVGElement? {
        guard let nameSVG = SVGUtilities.svg(of: self.identifier, using: source) else { return nil }
        guard var argSVG = self.argument.svg(using: source) else { return nil }
        argSVG = SVGUtilities.parentheses(argSVG, using: source)
        return SVGUtilities.compose(elements: [nameSVG, argSVG], spacing: SVGOptions.integerSpacing, alignment: .center, direction: .horizontal)
    }

    override public func evaluate(withValues values: [String: Double]) throws -> Double {
        return try .log(self.argument.evaluate(withValues: values))
    }

    override public func contains<T: Node>(nodeType: T.Type) -> [Id] {
        var ids: [Id] = []
        if(nodeType == Log.self) {
            ids.append(self.id)
        }
        ids.append(contentsOf: self.argument.contains(nodeType: nodeType))
        return ids
    }

    public override func replace(id: Id, with replacement: Node) throws -> Bool {
        guard id != self.id else {
            throw SymbolLabError.cannotReplaceNode("because cannot replace self.")
        }

        // Replace children
        if(self.argument.id == id) {
            self.argument = replacement
            return true
        }

        // Recursively(ish) search children
        return try self.argument.replace(id: id, with: replacement)
    }

    public override func getNode(withId id: Id) -> Node? {
        if(self.id == id) {
            return self
        }
        return self.argument.getNode(withId: id)
    }
}
