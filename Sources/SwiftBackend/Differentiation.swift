//
// Created by Ian Ruh on 11/2/20.
//
import SymbolLab

//[Assign(),
// Decimal(),
// Negative(),
// Add(),
// Subtract(),
// Multiply(),
// Divide(),
// Power(),
// Factorial(),
// Parentheses(),
// Derivative(),
// Integral(),
// Expand(),
// Sin(),
// AbsoluteValue(),
// ErrorFunction(),
// Cos(),
// Tan(),
// Sqrt(),
// Exp(),
// Log()]

/// Differentiate a given node.
///
/// - Parameters:
///   - term:
///   - variable:
/// - Returns: The derivative, or nil for 0
/// - Throws:
internal func differentiate(_ term: Node, wrt variableNode: Node) throws -> Node? {
    guard let variable = variableNode as? Variable else {
        // TODO: Figure out how to do this with matching
        preconditionFailure("Only can take derivative with respect to variables at the moment")
    }

    switch term {
    case let vari as Variable:
        if(vari == variable) {
            return Number(1)
        } else {
            return nil
        }
    case let num as Number:
        return nil
    case let assign as Assign:
        throw SwiftBackendError.cannotDifferentiate("Cannot differentiate assignment")
    case let decimal as Decimal:
        return nil
    case let negative as Negative:
        return try differentiate(negative, wrt: variable)
    case let add as Add:
        let left = try differentiate(add.left, wrt: variable)
        let right = try differentiate(add.right, wrt: variable)

        if (left != nil && right != nil) {
            return left! + right!
        } else if (left == nil && right != nil) {
            return right!
        } else if (left != nil && right == nil) {
            return left!
        } else {
            return nil
        }
    case let sub as Subtract:
        let left = try differentiate(sub.left, wrt: variable)
        let right = try differentiate(sub.right, wrt: variable)

        if (left != nil && right != nil) {
            return left! - right!
        } else if (left == nil && right != nil) {
            return -1*right!
        } else if (left != nil && right == nil) {
            return left!
        } else {
            return nil
        }
    case let mul as Multiply:
        let left = try differentiate(mul.left, wrt: variable)
        let right = try differentiate(mul.right, wrt: variable)

        if (left != nil && right != nil) {
            return mul.right*left! + mul.left*right!
        } else if (left == nil && right != nil) {
            return mul.left*right!
        } else if (left != nil && right == nil) {
            return mul.right*left!
        } else {
            return nil
        }
    case let div as Divide:
        let left = try differentiate(div.left, wrt: variable)
        let right = try differentiate(div.right, wrt: variable)

        if (left != nil && right != nil) {
            return (left!*div.right - right!*div.left) / Power([div.right, Number(2)])
        } else if (left == nil && right != nil) {
            return -1*(div.left*right!) / Power([div.right, Number(2)])
        } else if (left != nil && right == nil) {
            return (left!*div.right) / Power([div.right, Number(2)])
        } else {
            return nil
        }
    case let pow as Power:
        // This one is a bit ugly, but here it is nicely written out:
        // https://en.wikipedia.org/wiki/Differentiation_rules#Generalized_power_rule

        let dbase = try differentiate(pow.left, wrt: variable)
        let dpower = try differentiate(pow.right, wrt: variable)

        if (dbase != nil && dpower != nil) {
            return pow*(dbase!*pow.right/pow.left + dpower!*Log([pow.left]))
        } else if (dbase == nil && dpower != nil) {
            return pow*dpower!*Log(pow.left)
        } else if (dbase != nil && dpower == nil) {
            return pow*dbase!*pow.right/pow.left
        } else {
            return nil
        }
    case let fact as Factorial:
        throw SwiftBackendError.cannotDifferentiate("Cant differentiate \(term)")
    case let par as Parentheses:
        return try differentiate(par.param, wrt: variable)
    case let dir as Derivative:
        // TODO: Figure out what this entails precisely
        throw SwiftBackendError.cannotDifferentiate("Cant differentiate \(term)")
    case let int as Integral:
        // TODO: Implement, isn;t bad
        throw SwiftBackendError.cannotDifferentiate("Cant differentiate \(term)")
    case let exp as Expand:
        // TODO: Delete expand
        return try differentiate(exp.argument, wrt: variable)
    case let abs as AbsoluteValue:
        throw SwiftBackendError.cannotDifferentiate("Cant differentiate \(term)")
    case let erf as ErrorFunction:
        // TODO: Implement erf derivative
        return nil
    case let sin as Sin:
        let darg = try differentiate(sin.argument, wrt: variable)
        if(darg != nil) {
            return Cos(sin.argument)*darg!
        } else {
            return nil
        }
    case let cos as Cos:
        let darg = try differentiate(cos.argument, wrt: variable)
        if(darg != nil) {
            return -1*Sin(cos.argument)*darg!
        } else {
            return nil
        }
    case let tan as Tan:
        let darg = try differentiate(tan.argument, wrt: variable)
        if(darg != nil) {
            return 1/(Power([Cos(tan.argument), Number(2)])) * darg!
        } else {
            return nil
        }
    case let sqrt as Sqrt:
        return try differentiate(Power([sqrt.argument, Decimal(0.5)]), wrt: variable)
    case let exp as Exp:
        let dexp = try differentiate(exp.argument, wrt: variable)

        if(dexp != nil) {
            return exp*dexp!
        } else {
            return nil
        }
    case let log as Log:
        let dlog = try differentiate(log.argument, wrt: variable)

        if(dlog != nil) {
            return (1/log.argument)*dlog!
        } else {
            return nil
        }
    default:
        throw SwiftBackendError.cannotDifferentiate("Cant differentiate \(term)")
    }
}