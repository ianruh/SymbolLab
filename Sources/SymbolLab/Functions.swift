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
    
    public var param: Node // Store the parameter for the node
    
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
    
    @inlinable
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
    public var diffOf: Node
    public var withRespectTo: Node
    
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
    
    @inlinable
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
    public var argument: Node
    
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
    
    @inlinable
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
    public var argument: Node
    
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
    
    @inlinable
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
    public var argument: Node
    
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

    @inlinable
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
    public var argument: Node
    
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

    @inlinable
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
    public var argument: Node
    
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

    @inlinable
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
    public var argument: Node
    
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

    @inlinable
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

public class Sqrt: Node, Function {
    public let identifier: String = "sqrt"
    public let numArguments: Int = 1
    
    // Store the parameters for the node
    public var argument: Node
    
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

    @inlinable
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
    public var argument: Node
    
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

    @inlinable
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

    @inlinable
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
