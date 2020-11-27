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
    
    override public var variables: Set<Variable> {
        return self.diffOf.variables + self.withRespectTo.variables
    }

    override public var derivatives: Set<Derivative> {
        return [self]
    }

    override public var typeIdentifier: String {
        var hasher = Hasher()
        self.hash(into: &hasher)
        return "derivative\(hasher.finalize())"
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
    override public func evaluate(withValues values: [Node : Double]) throws -> Double {
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
        x_back[variable]! -= h
        var x_forward = values
        x_forward[variable]! += h

        return try (self.diffOf.evaluate(withValues: x_forward) - self.diffOf.evaluate(withValues: x_back)) / (2*h)
    }

    override internal func equals(_ otherNode: Node) -> Bool {
        if let dir = otherNode as? Derivative {
            return self.withRespectTo.equals(dir.withRespectTo) && self.diffOf.equals(dir.diffOf)
        } else {
            return false
        }
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

    public override func simplify() -> Node {
        if let newNode = differentiate(self.diffOf.simplify(), wrt: self.withRespectTo.simplify()) {
            if let dif = newNode as? Derivative {
                // To prevent recursion
                return newNode
            } else {
                return newNode.simplify()
            }
        } else {
            print("Unexpectedly found nil while simplifying a derivative: `\(self)`")
            return Number(0)
        }
    }

    override public func hash(into hasher: inout Hasher) {
        hasher.combine("derivative")
        hasher.combine(self.diffOf)
        hasher.combine(self.withRespectTo)
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
    
    override public var variables: Set<Variable> {
        return self.integrand.variables + self.withRespectTo.variables + self.lowerBound.variables + self.upperBound.variables
    }

    override public var derivatives: Set<Derivative> {
        return self.integrand.derivatives + 
            self.withRespectTo.derivatives + 
            self.lowerBound.derivatives + 
            self.upperBound.derivatives
    }

    override public var typeIdentifier: String {
        var hasher = Hasher()
        self.hash(into: &hasher)
        return "integral\(hasher.finalize())"
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

    override public func getSymbol<Engine:SymbolicMathEngine>(using type: Engine.Type) -> Engine.Symbol? {
        // TODO: Symbolic integration
        return nil
    }
    
    @inlinable
    override public func evaluate(withValues values: [Node: Double]) throws -> Double {
        // TODO: Numerical integration
        throw SymbolLabError.notApplicable(message: "Can't evaluate integrals")
    }

    override internal func equals(_ otherNode: Node) -> Bool {
        if let int = otherNode as? Integral {
            return self.integrand.equals(int.integrand) && 
                self.withRespectTo.equals(int.withRespectTo) && 
                self.lowerBound.equals(int.lowerBound) && 
                self.upperBound.equals(int.upperBound)
        } else {
            return false
        }
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

    public override func simplify() -> Node {
        return Integral([self.integrand.simplify(), self.withRespectTo.simplify(), self.upperBound.simplify(), self.lowerBound.simplify()])
    }

    override public func hash(into hasher: inout Hasher) {
        hasher.combine("integral")
        hasher.combine(self.integrand)
        hasher.combine(self.withRespectTo)
        hasher.combine(self.upperBound)
        hasher.combine(self.lowerBound)
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
    
    override public var variables: Set<Variable> {
        return self.argument.variables
    }

    override public var derivatives: Set<Derivative> {
        return self.argument.derivatives
    }

    override public var typeIdentifier: String {
        var hasher = Hasher()
        self.hash(into: &hasher)
        return "absolutevalue\(hasher.finalize())"
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
        return Engine.abs(param)
    }
    
    @inlinable
    override public func evaluate(withValues values: [Node: Double]) throws -> Double {
        let val = try self.argument.evaluate(withValues: values)
        return val > 0 ? val: -1*val
    }

    override internal func equals(_ otherNode: Node) -> Bool {
        if let abs = otherNode as? AbsoluteValue {
            return self.argument.equals(abs.argument)
        } else {
            return false
        }
    }

    override public func contains<T: Node>(nodeType: T.Type) -> [Id] {
        var ids: [Id] = []
        if(nodeType == AbsoluteValue.self) {
            ids.append(self.id)
        }
        ids.append(contentsOf: self.argument.contains(nodeType: nodeType))
        return ids
    }

    public override func simplify() -> Node {
        return AbsoluteValue(self.argument.simplify())
    }

    override public func hash(into hasher: inout Hasher) {
        hasher.combine("abs")
        hasher.combine(self.argument)
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
    
    override public var variables: Set<Variable> {
        return self.argument.variables
    }

    override public var derivatives: Set<Derivative> {
        return self.argument.derivatives
    }

    override public var typeIdentifier: String {
        var hasher = Hasher()
        self.hash(into: &hasher)
        return "errorfunction\(hasher.finalize())"
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
        return Engine.erf(param)
    }

    @inlinable
    override public func evaluate(withValues values: [Node: Double]) throws -> Double {
        throw SymbolLabError.notApplicable(message: "erf not implemneted yet")
    }

    override internal func equals(_ otherNode: Node) -> Bool {
        if let erf = otherNode as? ErrorFunction {
            return self.argument.equals(erf.argument)
        } else {
            return false
        }
    }

    override public func contains<T: Node>(nodeType: T.Type) -> [Id] {
        var ids: [Id] = []
        if(nodeType == ErrorFunction.self) {
            ids.append(self.id)
        }
        ids.append(contentsOf: self.argument.contains(nodeType: nodeType))
        return ids
    }

    public override func simplify() -> Node {
        return ErrorFunction(self.argument.simplify())
    }

    override public func hash(into hasher: inout Hasher) {
        hasher.combine("erf")
        hasher.combine(self.argument)
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
    
    override public var variables: Set<Variable> {
        return self.argument.variables
    }

    override public var derivatives: Set<Derivative> {
        return self.argument.derivatives
    }

    override public var typeIdentifier: String {
        var hasher = Hasher()
        self.hash(into: &hasher)
        return "sine\(hasher.finalize())"
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
        return Engine.sin(param)
    }

    @inlinable
    override public func evaluate(withValues values: [Node: Double]) throws -> Double {
        return try Double.sin(self.argument.evaluate(withValues: values))
    }

    override internal func equals(_ otherNode: Node) -> Bool {
        if let sin = otherNode as? Sin {
            return self.argument.equals(sin.argument)
        } else {
            return false
        }
    }

    override public func contains<T: Node>(nodeType: T.Type) -> [Id] {
        var ids: [Id] = []
        if(nodeType == Sin.self) {
            ids.append(self.id)
        }
        ids.append(contentsOf: self.argument.contains(nodeType: nodeType))
        return ids
    }

    public override func simplify() -> Node {
        return Sin(self.argument.simplify())
    }

    override public func hash(into hasher: inout Hasher) {
        hasher.combine("sin")
        hasher.combine(self.argument)
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
    
    override public var variables: Set<Variable> {
        return self.argument.variables
    }

    override public var derivatives: Set<Derivative> {
        return self.argument.derivatives
    }

    override public var typeIdentifier: String {
        var hasher = Hasher()
        self.hash(into: &hasher)
        return "cosine\(hasher.finalize())"
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
        return Engine.cos(param)
    }

    @inlinable
    override public func evaluate(withValues values: [Node: Double]) throws -> Double {
        return try Double.cos(self.argument.evaluate(withValues: values))
    }

    override internal func equals(_ otherNode: Node) -> Bool {
        if let cos = otherNode as? Cos {
            return self.argument.equals(cos.argument)
        } else {
            return false
        }
    }

    override public func contains<T: Node>(nodeType: T.Type) -> [Id] {
        var ids: [Id] = []
        if(nodeType == Cos.self) {
            ids.append(self.id)
        }
        ids.append(contentsOf: self.argument.contains(nodeType: nodeType))
        return ids
    }

    public override func simplify() -> Node {
        return Cos(self.argument.simplify())
    }

    override public func hash(into hasher: inout Hasher) {
        hasher.combine("cos")
        hasher.combine(self.argument)
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
    
    override public var variables: Set<Variable> {
        return self.argument.variables
    }

    override public var derivatives: Set<Derivative> {
        return self.argument.derivatives
    }

    override public var typeIdentifier: String {
        var hasher = Hasher()
        self.hash(into: &hasher)
        return "tangent\(hasher.finalize())"
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
        return Engine.tan(param)
    }

    @inlinable
    override public func evaluate(withValues values: [Node: Double]) throws -> Double {
        return try Double.tan(self.argument.evaluate(withValues: values))
    }

    override internal func equals(_ otherNode: Node) -> Bool {
        if let tan = otherNode as? Tan {
            return self.argument.equals(tan.argument)
        } else {
            return false
        }
    }

    override public func contains<T: Node>(nodeType: T.Type) -> [Id] {
        var ids: [Id] = []
        if(nodeType == Tan.self) {
            ids.append(self.id)
        }
        ids.append(contentsOf: self.argument.contains(nodeType: nodeType))
        return ids
    }

    public override func simplify() -> Node {
        return Tan(self.argument.simplify())
    }

    override public func hash(into hasher: inout Hasher) {
        hasher.combine("tan")
        hasher.combine(self.argument)
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
    
    override public var variables: Set<Variable> {
        return self.argument.variables
    }

    override public var derivatives: Set<Derivative> {
        return self.argument.derivatives
    }

    override public var typeIdentifier: String {
        var hasher = Hasher()
        self.hash(into: &hasher)
        return "squareroot\(hasher.finalize())"
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
        guard let param  = self.argument.getSymbol(using: type) else {return nil}
        return Engine.sqrt(param)
    }

    @inlinable
    override public func evaluate(withValues values: [Node: Double]) throws -> Double {
        return try Double.sqrt(self.argument.evaluate(withValues: values))
    }

    override internal func equals(_ otherNode: Node) -> Bool {
        if let sqrt = otherNode as? Sqrt {
            return self.argument.equals(sqrt.argument)
        } else {
            return false
        }
    }

    override public func contains<T: Node>(nodeType: T.Type) -> [Id] {
        var ids: [Id] = []
        if(nodeType == Sqrt.self) {
            ids.append(self.id)
        }
        ids.append(contentsOf: self.argument.contains(nodeType: nodeType))
        return ids
    }

    public override func simplify() -> Node {
        return Sqrt(self.argument.simplify())
    }

    override public func hash(into hasher: inout Hasher) {
        hasher.combine("sqrt")
        hasher.combine(self.argument)
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
    
    override public var variables: Set<Variable> {
        return self.argument.variables
    }

    override public var derivatives: Set<Derivative> {
        return self.argument.derivatives
    }

    override public var typeIdentifier: String {
        var hasher = Hasher()
        self.hash(into: &hasher)
        return "exponential\(hasher.finalize())"
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
        return Engine.exp(param)
    }

    @inlinable
    override public func evaluate(withValues values: [Node: Double]) throws -> Double {
        return try  Double.exp(self.argument.evaluate(withValues: values))
    }

    override internal func equals(_ otherNode: Node) -> Bool {
        if let exp = otherNode as? Exp {
            return self.argument.equals(exp.argument)
        } else {
            return false
        }
    }

    override public func contains<T: Node>(nodeType: T.Type) -> [Id] {
        var ids: [Id] = []
        if(nodeType == Exp.self) {
            ids.append(self.id)
        }
        ids.append(contentsOf: self.argument.contains(nodeType: nodeType))
        return ids
    }

    public override func simplify() -> Node {
        return Exp(self.argument.simplify())
    }

    override public func hash(into hasher: inout Hasher) {
        hasher.combine("exp")
        hasher.combine(self.argument)
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
