import SymEngine
import SymbolLab

precedencegroup ExponentiationPrecedence {
    associativity: right
    higherThan: MultiplicationPrecedence
}

infix operator ** : ExponentiationPrecedence

public struct SymEngineBackend: SymbolLab.SymbolicMathEngine {
    public typealias Symbol = SymEngine.Symbol

    private static let parser: Parser = Parser()

    /// A node representing the symbol
    public static func constructNode(from symbol: Symbol) -> Node? {
        /// TODO: Don't make the node by parsing. Figure out how to get the internal structure of the symbol from the SymEngine C API
        return Self.parser.parse(cString: symbol.symbolLabString)
    }

    /// Construct a symbol from an integer. This just wraps a SymEngine.Symbol initializer
    ///
    /// - Parameter integer: An integer value to assign to the new symbol
    /// - Returns: The new symbol
    public static func new(_ integer: Int) -> Symbol {
        return Symbol(integer)
    }

    /// Construct a symbol from an double. This just wraps a SymEngine.Symbol initializer
    ///
    /// - Parameter double: An double value to assign to the new symbol
    /// - Returns: The new symbol
    public static func new(_ double: Double) -> Symbol {
        return Symbol(double)
    }

    /// Construct a symbol from an string. This just wraps a SymEngine.Symbol initializer
    ///
    /// - Parameter variable: An variable to assign to the new symbol
    /// - Returns: The new symbol
    public static func new(_ variable: String) -> Symbol {
        return Symbol(name: variable)
    }

    public static func expand(_ param: Symbol) -> Symbol? {
        return SymEngine.expand(param)
    }

    public static func abs(_ param: Symbol) -> Symbol? {
        return SymEngine.abs(param)
    }

    public static func erf(_ param: Symbol) -> Symbol? {
        return SymEngine.erf(param)
    }

    public static func add(_ lhs: Symbol, _ rhs: Symbol) -> Symbol {
        return lhs + rhs
    }

    public static func subtract(_ lhs: Symbol, _ rhs: Symbol) -> Symbol {
        return lhs - rhs
    }

    public static func divide(_ lhs: Symbol, _ rhs: Symbol) -> Symbol {
        return lhs / rhs
    }

    public static func multiply(_ lhs: Symbol, _ rhs: Symbol) -> Symbol {
        return lhs * rhs
    }

    public static func negate(_ item: Symbol) -> Symbol {
        return -1 * item
    }

    public static func exponentiate(_ lhs: Symbol, _ rhs: Symbol) -> Symbol {
        return lhs ** rhs
    }

    public static func diff(of item: Symbol, withRespectTo: Symbol) -> Symbol? {
        return SymEngine.diff(of: item, withRespectTo: withRespectTo)
    }

    public static func sin(_ term: Symbol) -> Symbol? {
        return SymEngine.sin(term)
    }

    public static func cos(_ term: Symbol) -> Symbol? {
        return SymEngine.cos(term)
    }

    public static func tan(_ term: Symbol) -> Symbol? {
        return SymEngine.tan(term)
    }

    public static func log(_ term: Symbol) -> Symbol? {
        return SymEngine.log(term)
    }

    public static func sqrt(_ term: Symbol) -> Symbol? {
        return SymEngine.sqrt(term)
    }

    public static func exp(_ term: Symbol) -> Symbol? {
        return SymEngine.exp(term)
    }
}