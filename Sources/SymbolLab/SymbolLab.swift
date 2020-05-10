import SymEngine

public class Node {}

public class Op: Node {
    var left: Node
    var right: Node
    
    init(_ left: Node, _ right: Node) {
        self.left = left
        self.right = right
    }
}

public class Num: Node {
    
    // Value of the number
    var value: Double
    
    // Normal initializer
    public init(value: Double) {
        self.value = value
    }
}

public class Var: Node {
    
    // Value of the variable
    var symbol: String
    
    public init(_ symbol: String) {
        self.symbol = symbol
    }
}

public class Add: Op {}

public class Sub: Op {}

public class Mul: Op {}

public class Pow: Op {}

public class Div: Op {}
