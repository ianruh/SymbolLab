//
//  File.swift
//  
//
//  Created by Ian Ruh on 5/30/20.
//

import PythonKit
import SymbolLab

/**
 Get a python object back from the image property of the node.
 */
public func getImage(node: Node) -> PythonObject? {
    return node.image as? PythonObject
}

public struct ImageGeneratorOptions {
    public enum MultiplicationType {
        case explicitDot, explicitCross, implicit, mixed
    }
    public var multiplicationType: MultiplicationType
    
    public var numberSpacing: Int
    public var stringSpacing: Int
    public var compSpacing: Int
    
    public var exponentScale: Double
    public var exponentSpacing: Int
    
    
    public init() {
        self.multiplicationType = .mixed
        self.numberSpacing = 2
        self.stringSpacing = 2
        self.compSpacing = 20
        self.exponentScale = 0.3
        self.exponentSpacing = 5
    }
}

public struct BoundingBoxes {
    public var xmin: Int
    public var xmax: Int
    public var ymin: Int
    public var ymax: Int
}
