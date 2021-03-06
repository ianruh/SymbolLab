//
// Created by Ian Ruh on 11/2/20.
//

/// Take the total derivative
public func differentiate(_ term: Node, wrt variableNode: Node) -> Node? {
    return differentiate(term, wrt: variableNode, partially: false)
}

/// Take the partial derivative
public func partial(of term: Node, wrt variableNode: Node) -> Node? {
    return differentiate(term, wrt: variableNode, partially: true)
}


/// Differentiate a given node.
///
/// - Parameters:
///   - term:
///   - variable:
/// - Returns: The derivative, or nil for 0
/// - Throws:
private func differentiate(_ term: Node, wrt variableNode: Node, partially: Bool) -> Node? {
    guard let variable = variableNode as? Variable else {
        // TODO: Figure out how to do this with matching
        preconditionFailure("Only can take derivative with respect to variables at the moment")
    }

    switch term {
    case let vari as Variable:
        if(partially) {
            // Take the Partial derivative
            if(vari == variable) {
                return Number(1)
            } else {
                return Number(0)
            }
        } else {
            // Take the total derivative
            if(vari == variable) {
                return Number(1)
            } else {
                return Derivative(of: vari, wrt: variable)
            }
        }
    case let num as Number:
        return Number(0)
    case let assign as Assign:
        return nil
    case let negative as Negative:
        return differentiate(negative, wrt: variable, partially: partially)
    case let add as Add:
        var terms: [Node] = []

        for arg in add.arguments {
            if let der = differentiate(arg, wrt: variable, partially: partially) {
                terms.append(der)
            } else {
                return nil
            }
        }

        return Add(terms)
    case let sub as Subtract:
        let leftOp = differentiate(sub.left, wrt: variable, partially: partially)
        let rightOp = differentiate(sub.right, wrt: variable, partially: partially)

        guard let left = leftOp else {
            return nil
        }
        guard let right = rightOp else {
            return nil
        }

        return left - right
    case let mul as Multiply:
        var current: BinaryMultiply = BinaryMultiply(mul.arguments[0], mul.arguments[1])
        for i in 2..<mul.arguments.count {
            current = BinaryMultiply(mul.arguments[i], current)
        }
        return current.derivative(wrt: variable, partially: partially)
    case let div as Divide:
        let leftOp = differentiate(div.left, wrt: variable, partially: partially)
        let rightOp = differentiate(div.right, wrt: variable, partially: partially)

        guard let left = leftOp else {
            return nil
        }
        guard let right = rightOp else {
            return nil
        }

        return (left*div.right - right*div.left) / Power(div.right, Number(2))
    case let pow as Power:
        // This one is a bit ugly, but here it is nicely written out:
        // https://en.wikipedia.org/wiki/Differentiation_rules#Generalized_power_rule

        let dbaseOp = try differentiate(pow.left, wrt: variable, partially: partially)
        let dpowerOp = try differentiate(pow.right, wrt: variable, partially: partially)

        guard let dbase = dbaseOp else {
            return nil
        }
        guard let dpower = dpowerOp else {
            return nil
        }

        return pow*(dbase*pow.right/pow.left + dpower*Log([pow.left]))
    case let fact as Factorial:
        return nil
    case let dir as Derivative:
        // TODO: Figure out what this entails precisely
        return nil
    case let int as Integral:
        // TODO: Implement, isn;t bad
        return nil
    case let abs as AbsoluteValue:
        return nil
    case let erf as ErrorFunction:
        // TODO: Implement erf derivative
        return nil
    case let sin as Sin:
        let darg = differentiate(sin.argument, wrt: variable, partially: partially)
        if(darg != nil) {
            return Cos(sin.argument)*darg!
        } else {
            return nil
        }
    case let cos as Cos:
        let darg = differentiate(cos.argument, wrt: variable, partially: partially)
        if(darg != nil) {
            return -1*Sin(cos.argument)*darg!
        } else {
            return nil
        }
    case let tan as Tan:
        let darg = differentiate(tan.argument, wrt: variable, partially: partially)
        if(darg != nil) {
            return 1/(Power([Cos(tan.argument), Number(2)])) * darg!
        } else {
            return nil
        }
    case let sqrt as Sqrt:
        return differentiate(Power([sqrt.argument, Number(0.5)]), wrt: variable, partially: partially)
    case let exp as Exp:
        let dexp = differentiate(exp.argument, wrt: variable, partially: partially)

        if(dexp != nil) {
            return exp*dexp!
        } else {
            return nil
        }
    case let log as Log:
        let dlog = differentiate(log.argument, wrt: variable, partially: partially)

        if(dlog != nil) {
            return (1/log.argument)*dlog!
        } else {
            return nil
        }
    default:
        return nil
    }
}

private struct BinaryMultiply {
    var left: Node
    var right: Node

    init(_ left: Node, _ right: Node) {
        self.left = left
        self.right = right
    }

    init(_ left: Node, _ right: BinaryMultiply) {
        self.left = left
        self.right = Multiply(right.left, right.right)
    }

    func derivative(wrt variable: Node, partially: Bool) -> Node? {
        let dleftOp = differentiate(self.left, wrt: variable, partially: partially)
        let drightOp = differentiate(self.right, wrt: variable, partially: partially)

        guard let dleft = dleftOp else {
            return nil
        }
        guard let dright = drightOp else {
            return nil
        }

        return self.right*dleft + self.left*dright
    }
}