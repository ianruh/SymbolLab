//
//  File.swift
//  
//
//  Created by Ian Ruh on 5/30/20.
//

import PythonKit
import SymbolLab

public typealias EquationImage = (image: PythonObject, boundingBoxes: PythonObject)

//[Assign([P,P]),
//Decimal([P,P]),
//Negative([P]),
//Add([P,P]),
//Subtract([P,P]),
//Multiply([P,P]),
//Divide([P,P]),
//Power([P,P]),
//Factorial([P]),
//Parentheses([P]),
//Derivative([P,P]),
//Integral([P,P,P,P]),
//Expand([P]),
//Sin([P]),
//AbsoluteValue([P]),
//ErrorFunction([P]),
//Cos([P]),
//Tan([P]),
//Asin([P]),
//Acos([P]),
//Atan([P]),
//Csc([P]),
//Sec([P]),
//Cot([P]),
//Acsc([P]),
//Asec([P]),
//Acot([P]),
//Sinh([P]),
//Cosh([P]),
//Tanh([P]),
//Asinh([P]),
//Acosh([P]),
//Atanh([P]),
//Csch([P]),
//Sech([P]),
//Coth([P]),
//Acsch([P]),
//Asech([P]),
//Acoth([P]),
//Sqrt([P]),
//Exp([P]),
//Log([P])]

/**
 Get a python object back from the image property of the node.
 
 A case need's to be added to this for every node.
 */
public func getImage(node: Node, using imageHandler: ImageHandler) -> EquationImage? {
    switch node {
    case let number as Number:
        return number.getImage(using: imageHandler)
    case let variable as Variable:
        return variable.getImage(using: imageHandler)
    case let assign as Assign:
        return assign.getImage(using: imageHandler)
    default:
        return nil
    }
}

public struct ImageGeneratorOptions {
    public enum MultiplicationType {
        case explicitDot, explicitCross, implicit, mixed
    }
    public var multiplicationType: MultiplicationType
    
    public var numberSpacing: Int
    public var stringSpacing: Int
    public var compSpacing: Int
    public var parenthesesSpacing: Int
    public var fractionSpacing: Int
    
    public var exponentScale: Double
    public var exponentSpacing: Int
    
    
    public init() {
        self.multiplicationType = .mixed
        self.numberSpacing = 2
        self.stringSpacing = 2
        self.compSpacing = 20
        self.exponentScale = 0.3
        self.exponentSpacing = 5
        self.parenthesesSpacing = 10
        self.fractionSpacing = 20
    }
}

public struct BoundingBoxes {
    public var xmin: Int
    public var xmax: Int
    public var ymin: Int
    public var ymax: Int
}
