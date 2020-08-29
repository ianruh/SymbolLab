//
// Created by Ian Ruh on 8/29/20.
//

// We have node, variable, and number versions here.

//------------------------- Custom Precedence --------------------

// New precidence for power
precedencegroup ExponentiationPrecedence {
    associativity: right
    higherThan: MultiplicationPrecedence
}



//------------------------- Custom Operators --------------------

infix operator ** : ExponentiationPrecedence
infix operator ~ : AssignmentPrecedence

//------------------------- Operations --------------------

/// Add operator for nodes
///
/// - Parameters:
///   - lhs: Left side of infix operation
///   - rhs: Right side of infix operation
/// - Returns: New node adding the two
public func +(_ lhs: Node, _ rhs: Node) -> Node {
    return Add([lhs, rhs])
}
public func +(_ lhs: Node, _ rhs: Number) -> Node {
    return Add([lhs, rhs])
}
public func +(_ lhs: Number, _ rhs: Node) -> Node {
    return Add([lhs, rhs])
}
public func +(_ lhs: Node, _ rhs: Decimal) -> Node {
    return Add([lhs, rhs])
}
public func +(_ lhs: Decimal, _ rhs: Node) -> Node {
    return Add([lhs, rhs])
}

/// Subtract operator for nodes
///
/// - Parameters:
///   - lhs:
///   - rhs:
/// - Returns:
public func -(_ lhs: Node, _ rhs: Node) -> Node {
    return Subtract([lhs, rhs])
}
public func -(_ lhs: Node, _ rhs: Number) -> Node {
    return Subtract([lhs, rhs])
}
public func -(_ lhs: Number, _ rhs: Node) -> Node {
    return Subtract([lhs, rhs])
}
public func -(_ lhs: Node, _ rhs: Decimal) -> Node {
    return Subtract([lhs, rhs])
}
public func -(_ lhs: Decimal, _ rhs: Node) -> Node {
    return Subtract([lhs, rhs])
}

/// Divide operator for nodes
///
/// - Parameters:
///   - lhs:
///   - rhs:
/// - Returns:
public func /(_ lhs: Node, _ rhs: Node) -> Node {
    return Divide([lhs, rhs])
}
public func /(_ lhs: Node, _ rhs: Number) -> Node {
    return Divide([lhs, rhs])
}
public func /(_ lhs: Number, _ rhs: Node) -> Node {
    return Divide([lhs, rhs])
}
public func /(_ lhs: Node, _ rhs: Decimal) -> Node {
    return Divide([lhs, rhs])
}
public func /(_ lhs: Decimal, _ rhs: Node) -> Node {
    return Divide([lhs, rhs])
}

/// Multiply operator for nodes
///
/// - Parameters:
///   - lhs:
///   - rhs:
/// - Returns:
public func *(_ lhs: Node, _ rhs: Node) -> Node {
    return Multiply([lhs, rhs])
}
public func *(_ lhs: Node, _ rhs: Number) -> Node {
    return Multiply([lhs, rhs])
}
public func *(_ lhs: Number, _ rhs: Node) -> Node {
    return Multiply([lhs, rhs])
}
public func *(_ lhs: Node, _ rhs: Decimal) -> Node {
    return Multiply([lhs, rhs])
}
public func *(_ lhs: Decimal, _ rhs: Node) -> Node {
    return Multiply([lhs, rhs])
}

/// Take the lhs to the power of the rhs
///
/// - Parameters:
///   - lhs:
///   - rhs:
/// - Returns:
public func **(_ lhs: Node, _ rhs: Node) -> Node {
    return Power([lhs, rhs])
}
public func **(_ lhs: Node, _ rhs: Number) -> Node {
    return Power([lhs, rhs])
}
public func **(_ lhs: Number, _ rhs: Node) -> Node {
    return Power([lhs, rhs])
}
public func **(_ lhs: Node, _ rhs: Decimal) -> Node {
    return Power([lhs, rhs])
}
public func **(_ lhs: Decimal, _ rhs: Node) -> Node {
    return Power([lhs, rhs])
}

/// Assign the lhs to the  rhs
///
/// - Parameters:
///   - lhs:
///   - rhs:
/// - Returns:
public func ~(_ lhs: Node, _ rhs: Node) -> Node {
    return Assign([lhs, rhs])
}
public func ~(_ lhs: Number, _ rhs: Node) -> Node {
    return Assign([lhs, rhs])
}
public func ~(_ lhs: Node, _ rhs: Number) -> Node {
    return Assign([lhs, rhs])
}
public func ~(_ lhs: Node, _ rhs: Decimal) -> Node {
    return Assign([lhs, rhs])
}
public func ~(_ lhs: Decimal, _ rhs: Node) -> Node {
    return Assign([lhs, rhs])
}