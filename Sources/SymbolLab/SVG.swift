//
//  File.swift
//  
//
//  Created by Ian Ruh on 5/24/20.
//

import Foundation

public protocol SVGElement: CustomStringConvertible {}

extension SVGElement {
    public func writeToDisk(path: String) throws {
        let url: URL = URL(fileURLWithPath: path)
        try self.description.write(to: url, atomically: true, encoding: .utf8)
    }
}

public protocol Resizable {
    mutating func resize(percentWidth: Double, percentHeight: Double)
    mutating func resize(width: Double, height: Double)
}

public struct ViewBox: CustomStringConvertible {
    var xmin: Double
    var ymin: Double
    var width: Double
    var height: Double
    
    public var description: String {
        return "\(self.xmin) \(self.ymin) \(self.width) \(self.height)"
    }
    
    public init(_ xmin: Double, _ ymin: Double, _ width: Double, _ height: Double) {
        self.xmin = xmin
        self.ymin = ymin
        self.width = width
        self.height = height
    }
}

public class SVG: SVGElement, Resizable {
    var children: [SVGElement]
    public var height: Double
    public var width: Double
    var viewbox: ViewBox
    var preserveAspectRatio: Bool
    var x: Double
    var y: Double
    
    public var description: String {
        var str = """
        <svg x="\(self.x)" y="\(self.y)" width="\(self.width)" height="\(self.height)" viewBox="\(self.viewbox)" preserveAspectRatio="\(self.preserveAspectRatio ? "xMidYMid": "none")">\n
        """
        for child in self.children {
            str.append(child.description)
            str.append("\n")
        }
        str.append("</svg>")
        return str
    }
    
    public init(x: Double, y: Double, width: Double, height: Double, viewBox: ViewBox, preserveAspectRatio: Bool = false, children: [SVGElement]) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.viewbox = viewBox
        self.preserveAspectRatio = preserveAspectRatio
        self.children = children
    }
    
    /**
     Defuault resizing that should probably be overriden by children.
     */
    public func resize(percentWidth: Double, percentHeight: Double) {
        self.height = self.height*percentHeight
        self.width = self.width*percentWidth
    }
    
    public func resize(width: Double, height: Double) {
        
    }
    
}

public struct BoundingBox {
    var x: Double
    var y: Double
    var width: Double
    var height: Double
    
    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
    
    public init(top: Double, bottom: Double, left: Double, right: Double) {
        self.x = left
        self.y = top
        self.width = right - left
        self.height = bottom - top
    }
}
protocol PathElement: CustomStringConvertible, Resizable {
    var boundingBox: BoundingBox? {get}
}

struct Point: CustomStringConvertible {
    var x: Double
    var y: Double
    
    public var description: String {
        return "\(self.x) \(self.y)"
    }
}

struct M: PathElement {
    var pt: Point
    
    var description: String {
        return "M \(self.pt)"
    }
    
    var boundingBox: BoundingBox? {
        return BoundingBox(x: self.pt.x, y: self.pt.y, width: 0, height: 0)
    }
    
    init(x: Double, y: Double) {
        self.pt = Point(x: x, y: y)
    }
    
    mutating func resize(percentWidth: Double, percentHeight: Double) {
        self.pt.x *= percentWidth
        self.pt.y *= percentHeight
    }
    
    /**
     This function is meaning less for a point, so it doesn't do anything.
     */
    mutating func resize(width: Double, height: Double) {}
}

struct C: PathElement {
    
    var controlPoints: [Point]
    
    var description: String {
        return "C \(self.controlPoints.join(separator: " "))"
    }
    
    var boundingBox: BoundingBox? {
        let minX = self.controlPoints.map({$0.x}).min()!
        let maxX = self.controlPoints.map({$0.x}).max()!
        let minY = self.controlPoints.map({$0.y}).min()!
        let maxY = self.controlPoints.map({$0.y}).max()!
        return BoundingBox(top: minY, bottom: maxY, left: minX, right: maxX)
    }
    
    mutating func resize(percentWidth: Double, percentHeight: Double) {
        for (i,_) in self.controlPoints.enumerated() {
            self.controlPoints[i].x *= percentWidth
            self.controlPoints[i].y *= percentHeight
        }
    }
    
    mutating func resize(width: Double, height: Double) {
        let bb = self.boundingBox
        let pW = width/bb!.width
        let pH = height/bb!.height
        self.resize(percentWidth: pW, percentHeight: pH)
    }
}
 
struct L: PathElement {
    var pt: Point
    
    var description: String {
        return "L \(self.pt)"
    }
    
    var boundingBox: BoundingBox? {
        return BoundingBox(x: self.pt.x, y: self.pt.y, width: 0, height: 0)
    }
    
    init(x: Double, y: Double) {
        self.pt = Point(x: x, y: y)
    }
    
    mutating func resize(percentWidth: Double, percentHeight: Double) {
        self.pt.x *= percentWidth
        self.pt.y *= percentHeight
    }
    
    /**
     This function is meaning less for a point, so it doesn't do anything.
     */
    mutating func resize(width: Double, height: Double) {}
}

/**
 This is a close path one, so we don't do anything with it.
 */
struct Z: PathElement {
    var description: String {
        return "Z"
    }
    
    var boundingBox: BoundingBox? = nil
    
    mutating func resize(percentWidth: Double, percentHeight: Double) {}
    mutating func resize(width: Double, height: Double) {}
}

public struct SVGPath: SVGElement, Resizable {
    public var fill: String
    public var stroke: String
    public var strokeWidth: Double
    public var d: String {
        var str = ""
        for p in self.pathElements {
            str += "\(p) "
        }
        return str
    }
    var pathElements: [PathElement] = []
    
    public var boundingBox: BoundingBox? {
        let boundingBoxes = self.pathElements.map({$0.boundingBox})
//        let xmin = boundingBoxes.map({$0?.x}).max(by: {$0 > $1})
        #warning("SVG not implemented yet")
        return nil
    }
    
    public var description: String {
        return """
        <path fill="\(self.fill)" stroke="\(self.stroke)" stroke-width="\(self.strokeWidth)rem" d="\(self.d)" />
        """
    }
    
    init(fill: String = "none", stroke: String = "black", strokeWidth: Double = 0, pathElements: [PathElement]) {
        self.fill = fill
        self.stroke = stroke
        self.strokeWidth = strokeWidth
    }
    
    public mutating func resize(percentWidth: Double, percentHeight: Double) {
        #warning("SVG not implemented  yet")
    }
    
    public mutating func resize(width: Double, height: Double) {
        #warning("SVG not implemented  yet")
    }
}
