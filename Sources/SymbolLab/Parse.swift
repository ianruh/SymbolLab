//
//  File.swift
//  
//
//  Created by Ian Ruh on 5/9/20.
//

import Foundation

// If you add any operators or precedence levels make sure to also add them
// to the lists of both at the end.
//
// Also, parentheses are implictly the highest precedence.

//##################### PROTOCOLS ######################
internal enum StringAssociativity {
    case left, none, right
}

internal enum StringOperatorType {
    case prefix, infix, postfix
}

internal protocol StringOperatorPrecedence {
    var higherThan: StringOperatorPrecedence? { get }
}

internal protocol StringOperator: Comparable {
    var str: String { get }
    var precedence: StringOperatorPrecedence { get }
    var associativity: StringAssociativity { get }
    var type: StringOperatorType { get }
}

extension StringOperatorPrecedence {
    func getLevel() -> Int {
        var count: Int = 0
        var current: StringOperatorPrecedence = self
        while(current.higherThan != nil) {
            count += 1
            current = current.higherThan!
        }
        return count
    }
}

extension StringOperator {
    /**
    Instance method for comparable protocol.
    */
    static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.precedence.getLevel() < rhs.precedence.getLevel()
    }
    
    /**
    Instance method for equitable protocol.
    */
    static func == (lhs: Self, rhs: Self) -> Bool {
        return (lhs.precedence.getLevel() == rhs.precedence.getLevel()) &&
            (lhs.str == rhs.str) &&
            (lhs.associativity == rhs.associativity)
    }
}

//################# PRECEDENCE LEVELS ###################

/**
 This is the lowest precedence. Everything comes before this. Thus we indicate
 it using nil.
 */
internal struct StringAssignmentPrecedence: StringOperatorPrecedence {
    let higherThan: StringOperatorPrecedence? = nil
}

/**
    Precedence for addition.
 */
internal struct StringAdditionPrecedence: StringOperatorPrecedence {
    let higherThan: StringOperatorPrecedence? = StringAssignmentPrecedence()
}

/**
    Precedence for multiplication.
 */
internal struct StringMultiplicationPrecedence: StringOperatorPrecedence {
    let higherThan: StringOperatorPrecedence? = StringAdditionPrecedence()
}

/**
    Precedence for exponentiation.
 */
internal struct StringExponentPrecedence: StringOperatorPrecedence {
    let higherThan: StringOperatorPrecedence? = StringMultiplicationPrecedence()
}

//#################### OPERATORS ######################

internal struct StringAssignmentOperator: StringOperator {
    let str: String = "="
    let precedence: StringOperatorPrecedence = StringAssignmentPrecedence()
    let associativity: StringAssociativity = .right
    var type: StringOperatorType = .infix
}

internal struct StringAdditionOperator: StringOperator {
    let str: String = "+"
    let precedence: StringOperatorPrecedence = StringAdditionPrecedence()
    let associativity: StringAssociativity = .left
    var type: StringOperatorType = .infix
}

internal struct StringSubtractionOperator: StringOperator {
    let str: String = "-"
    let precedence: StringOperatorPrecedence = StringAdditionPrecedence()
    let associativity: StringAssociativity = .left
    var type: StringOperatorType = .infix
}

internal struct StringMultiplicationOperator: StringOperator {
    let str: String = "*"
    let precedence: StringOperatorPrecedence = StringMultiplicationPrecedence()
    let associativity: StringAssociativity = .left
    var type: StringOperatorType = .infix
}

internal struct StringDivisionOperator: StringOperator {
    let str: String = "/"
    let precedence: StringOperatorPrecedence = StringMultiplicationPrecedence()
    let associativity: StringAssociativity = .left
    var type: StringOperatorType = .infix
}

internal struct StringExponentOperator: StringOperator {
    let str: String = "^"
    let precedence: StringOperatorPrecedence = StringExponentPrecedence()
    let associativity: StringAssociativity = .right
    var type: StringOperatorType = .infix
}

//##################### LISTS #######################

let stringOperators: [StringOperator] = [StringAssignmentOperator(),
                                              StringAdditionOperator(),
                                              StringSubtractionOperator(),
                                              StringMultiplicationOperator(),
                                              StringDivisionOperator(),
                                              StringExponentOperator()]

//#################### PARSERS ######################

//extension Node {
//    private var stringOperatorGroups {}
//
//    public static func parseCString(_ str: String) -> Node {
//
//    }
//}
