import SymbolLab

public enum SwiftBackendError: Error {
    case cannotDifferentiate(_ msg: String)
}

precedencegroup ExponentiationPrecedence {
    associativity: right
    higherThan: MultiplicationPrecedence
}

// infix operator ** : ExponentiationPrecedence

public struct SwiftBackend: SymbolLab.SymbolicMathEngine {
    public typealias Symbol = Node

    /// A node representing the symbol
    public static func constructNode(from symbol: Symbol) -> Node? {
        return symbol
    }

    /// Construct a symbol from an integer. This just wraps a SymEngine.Symbol initializer
    ///
    /// - Parameter integer: An integer value to assign to the new symbol
    /// - Returns: The new symbol
    public static func new(_ integer: Int) -> Symbol {
        return SymbolLab.Number(integer)
    }

    /// Construct a symbol from an double. This just wraps a SymEngine.Symbol initializer
    ///
    /// - Parameter double: An double value to assign to the new symbol
    /// - Returns: The new symbol
    public static func new(_ double: Double) -> Symbol {
        return SymbolLab.Number(double)
    }

    /// Construct a symbol from an string. This just wraps a SymEngine.Symbol initializer
    ///
    /// - Parameter variable: An variable to assign to the new symbol
    /// - Returns: The new symbol
    public static func new(_ variable: String) -> Symbol {
        return SymbolLab.Variable(variable)
    }

    public static func expand(_ param: Symbol) -> Symbol? {
        // TODO: Decide if this should even exist at all
        return nil
    }

    public static func abs(_ param: Symbol) -> Symbol? {
        return SymbolLab.AbsoluteValue([param])
    }

    public static func erf(_ param: Symbol) -> Symbol? {
        return SymbolLab.ErrorFunction([param])
    }

    public static func add(_ params: [Symbol]) -> Symbol {
        return Add(params)
    }

    public static func subtract(_ lhs: Symbol, _ rhs: Symbol) -> Symbol {
        return lhs - rhs
    }

    public static func divide(_ lhs: Symbol, _ rhs: Symbol) -> Symbol {
        return lhs / rhs
    }

    public static func multiply(_ params: [Symbol]) -> Symbol {
        return Multiply(params)
    }

    public static func negate(_ item: Symbol) -> Symbol {
        return -1 * item
    }

    public static func exponentiate(_ lhs: Symbol, _ rhs: Symbol) -> Symbol {
        return lhs ** rhs
    }

    public static func diff(of item: Symbol, withRespectTo: Symbol) -> Symbol? {
        return differentiate(item, wrt: withRespectTo, partially: false)
    }

    public static func partial(of item: Symbol, withRespectTo: Symbol) -> Symbol? {
        return differentiate(item, wrt: withRespectTo, partially: true)
    }

    public static func sin(_ term: Symbol) -> Symbol? {
        return SymbolLab.Sin([term])
    }

    public static func cos(_ term: Symbol) -> Symbol? {
        return SymbolLab.Cos([term])
    }

    public static func tan(_ term: Symbol) -> Symbol? {
        return SymbolLab.Tan([term])
    }

    public static func log(_ term: Symbol) -> Symbol? {
        return SymbolLab.Log([term])
    }

    public static func sqrt(_ term: Symbol) -> Symbol? {
        return SymbolLab.Sqrt(term)
    }

    public static func exp(_ term: Symbol) -> Symbol? {
        return SymbolLab.Exp(term)
    }
}