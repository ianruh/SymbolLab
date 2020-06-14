//
//  File.swift
//  
//
//  Created by Ian Ruh on 5/24/20.
//

import Foundation

/**
 Protocol defines the operations necessary for an element to be resized.
 */
public protocol Resizable {
    mutating func resize(percentWidth: Double, percentHeight: Double)
    mutating func resize(width: Double, height: Double)
}

extension Resizable {
    mutating func scale(by: Double) {
        self.resize(percentWidth: by, percentHeight: by)
    }
}

/**
 Protocol defines the operations needed for an element to be translated.
 */
public protocol Movable {
    mutating func move(dx: Double, dy: Double)
}

extension Movable {
    mutating func moveX(_ dx: Double) {
        self.move(dx: dx, dy: 0)
    }
    mutating func moveY(_ dy: Double) {
        self.move(dx: 0, dy: dy)
    }
}

/**
 Protocol serves as the main protocol for any SVG element.
 */
public protocol SVGElement: CustomStringConvertible, Resizable, Movable {
    var boundingBox: BoundingBox? {get}
}

extension SVGElement {
    /**
     Write the svg to disk at the given absolute path.
     */
    public func writeToDisk(path: String) throws {
        let url: URL = URL(fileURLWithPath: path)
        try self.description.write(to: url, atomically: true, encoding: .utf8)
    }
}

/**
 Struct encapsulates the values necessary for an SVG viewbox.
 */
public struct ViewBox: CustomStringConvertible {
    var xmin: Double
    var ymin: Double
    var width: Double
    var height: Double
    
    public var description: String {
        return "\(self.xmin.sixAc) \(self.ymin.sixAc) \(self.width.sixAc) \(self.height.sixAc)"
    }
    
    public init(_ xmin: Double, _ ymin: Double, _ width: Double, _ height: Double) {
        self.xmin = xmin
        self.ymin = ymin
        self.width = width
        self.height = height
    }
    
    public init(bbox: BoundingBox) {
        self.xmin = bbox.xmin
        self.ymin = bbox.ymin
        self.width = bbox.width
        self.height = bbox.height
    }
}

/**
 Utility struct for storing and working with bounding boxes.
 */
public struct BoundingBox {
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double
    
    public var xmin: Double {
        return self.x
    }
    public var ymin: Double {
        return self.y
    }
    public var xmax: Double {
        return self.x + self.width
    }
    public var ymax: Double {
        return self.y + self.height
    }
    
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
    
    public static func of(boxes: [BoundingBox?]) -> BoundingBox? {
        var xmin: Double?
        var ymin: Double?
        var xmax: Double?
        var ymax: Double?
        for i in 0..<boxes.count {
            if let box = boxes[i] {
                // xmin
                if xmin == nil {
                    xmin = box.xmin
                } else {
                    xmin = box.xmin < xmin! ? box.xmin : xmin
                }
                // ymin
                if ymin == nil {
                    ymin = box.ymin
                } else {
                    ymin = box.ymin < ymin! ? box.ymin : ymin
                }
                // xmax
                if xmax == nil {
                    xmax = box.xmax
                } else {
                    xmax = box.xmax > xmax! ? box.xmax : xmax
                }
                // ymax
                if ymax == nil {
                    ymax = box.ymax
                } else {
                    ymax = box.ymax > ymax! ? box.ymax : ymax
                }
            }
        }
        guard let minx = xmin else {
            return nil
        }
        guard let miny = ymin else {
            return nil
        }
        guard let maxx = xmax else {
            return nil
        }
        guard let maxy = ymax else {
            return nil
        }
        return BoundingBox(top: miny, bottom: maxy, left: minx, right: maxx)
    }
}

/**
 The base class for an SVG image. Is also an SVGELement so they can be nested.
 */
public class SVG: SVGElement {
    /**
     Store all of the elements in the SVG
     */
    var children: [SVGElement]
    
    // The height and width of the SVG
    public var height: Double
    public var width: Double
    
    // Coordinates of the SVG
    var x: Double
    var y: Double
    
    public var boundingBox: BoundingBox? {
        if(self.children.count > 0) {
            let boxes = self.children.map({$0.boundingBox})
            if let box = BoundingBox.of(boxes: boxes) {
                return box
            }
        }
        return BoundingBox(x: 0, y: 0, width: 0, height: 0)
    }
    
    // View box of the SVG
    var viewbox: ViewBox {
        return ViewBox(bbox: self.boundingBox!)
    }
    
    // Should aspect ratio be preserved in resizing
    var preserveAspectRatio: Bool
    
    public var description: String {
        var str = """
        <svg x="\(self.x.sixAc)" y="\(self.y.sixAc)" width="\(self.width.sixAc)" height="\(self.height.sixAc)" viewBox="\(self.viewbox)" preserveAspectRatio="\(self.preserveAspectRatio ? "xMidYMid": "none")">\n
        """
        for child in self.children {
            str.append(child.description)
            str.append("\n")
        }
        str.append("</svg>")
        return str
    }
    
    public init(x: Double = 0, y: Double = 0, width: Double = 100, height: Double = 100, preserveAspectRatio: Bool = true, children: [SVGElement]) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.preserveAspectRatio = preserveAspectRatio
        self.children = children
    }
    
    /**
     Defuault resizing that should probably be overriden by children.
     */
    public func resize(percentWidth: Double, percentHeight: Double) {
        for i in 0 ..< self.children.count {
            self.children[i].resize(percentWidth: percentWidth, percentHeight: percentHeight)
        }
    }
    
    public func resize(width: Double, height: Double) {
        let bbox = self.boundingBox!
        let pheight = height/bbox.height
        let pwidth = width/bbox.width
        self.resize(percentWidth: pwidth, percentHeight: pheight)
    }
    
    public func move(dx: Double, dy: Double) {
        for i in 0 ..< self.children.count {
            self.children[i].move(dx: dx, dy: dy)
        }
    }
    
    public func paste(path: SVGElement, withTopLeftAt tl: Point) {
        var pathVar = path
        pathVar.move(dx: tl.x, dy: tl.y)
        
        switch pathVar {
        case let svg as SVG:
            self.children.append(contentsOf: svg.children)
        default:
            self.children.append(pathVar)
        }
    }
    
    public func paste(path: SVGElement, withCenterLeftAt cl: Point) {
        var pathVar = path
        let bbox = pathVar.boundingBox!
        pathVar.move(dx: cl.x, dy: cl.y-bbox.height/2)
        
        switch pathVar {
        case let svg as SVG:
            self.children.append(contentsOf: svg.children)
        default:
            self.children.append(pathVar)
        }
    }
    
    public func paste(path: SVGElement, withBottomLeftAt bl: Point) {
        var pathVar = path
        let bbox = pathVar.boundingBox!
        pathVar.move(dx: bl.x, dy: bl.y-bbox.height)
        
        switch pathVar {
        case let svg as SVG:
            self.children.append(contentsOf: svg.children)
        default:
            self.children.append(pathVar)
        }
    }
    
    public func paste(path: SVGElement, withCenterTopAt ct: Point) {
        var pathVar = path
        let bbox = pathVar.boundingBox!
        pathVar.move(dx: ct.x-bbox.width/2, dy: ct.y)
        
        switch pathVar {
        case let svg as SVG:
            self.children.append(contentsOf: svg.children)
        default:
            self.children.append(pathVar)
        }
    }
    
    public func paste(path: SVGElement, withCenterAt c: Point) {
        var pathVar = path
        let bbox = pathVar.boundingBox!
        pathVar.move(dx: c.x-bbox.width/2, dy: c.y-bbox.height/2)
        
        switch pathVar {
        case let svg as SVG:
            self.children.append(contentsOf: svg.children)
        default:
            self.children.append(pathVar)
        }
    }
    
    /**
     Minimize the path by shiftng everything to the upper left.
     */
    public func minimizeSVG() {
        let boxes = self.children.map({$0.boundingBox})
        if let box = BoundingBox.of(boxes: boxes) {
            self.move(dx: -1*box.x, dy: -1*box.y)
        }
    }
}

public protocol PathElement: CustomStringConvertible, Resizable, Movable {
    var boundingBox: BoundingBox? {get}
}

public struct Point: CustomStringConvertible {
    var x: Double
    var y: Double
    
    public var description: String {
        return "\(self.x.sixAc) \(self.y.sixAc)"
    }
    
    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
    
    public init(_ x: Double, _ y: Double) {
        self.x = x
        self.y = y
    }
}
/**
 Move the current point to the coordinate x,y. Any subsequent coordinate pair(s) are interpreted as parameter(s) for implicit absolute LineTo (L) command(s) (see below).
 */
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
    
    mutating func move(dx: Double, dy: Double) {
        self.pt.x += dx
        self.pt.y += dy
    }
}

/**
 Draw a cubic Bézier curve from the current point to the end point specified by x,y. The start control point is specified by x1,y1 and the end control point is specified by x2,y2. Any subsequent triplet(s) of coordinate pairs are interpreted as parameter(s) for implicit absolute cubic Bézier curve (C) command(s).
 */
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
    
    init(controlPoints: [Point]) {
        self.controlPoints = controlPoints
    }
    
    mutating func resize(percentWidth: Double, percentHeight: Double) {
        for (i,_) in self.controlPoints.enumerated() {
            self.controlPoints[i].x *= percentWidth
            self.controlPoints[i].y *= percentHeight
        }
    }
    
    mutating func resize(width: Double, height: Double) {}
    
    mutating func move(dx: Double, dy: Double) {
        for (i,_) in self.controlPoints.enumerated() {
            self.controlPoints[i].x += dx
            self.controlPoints[i].y += dy
        }
    }
}
 
/**
 Draw a line from the current point to the end point specified by x,y. Any subsequent coordinate pair(s) are interpreted as parameter(s) for implicit absolute LineTo (L) command(s).
 */
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
    
    mutating func move(dx: Double, dy: Double) {
        self.pt.x += dx
        self.pt.y += dy
    }
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
    mutating func move(dx: Double, dy: Double) {}
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
    
    /**
     The bounding box of the path.
     */
    public var boundingBox: BoundingBox? {
        let boxes = self.pathElements.map({$0.boundingBox})
        return BoundingBox.of(boxes: boxes)
    }
    
    public var description: String {
        return """
        <path fill="\(self.fill)" stroke="\(self.stroke)" stroke-width="\(self.strokeWidth)rem" d="\(self.d)" />
        """
    }
    
    init(fill: String = "black", stroke: String = "black", strokeWidth: Double = 0, pathElements: [PathElement]) {
        self.fill = fill
        self.stroke = stroke
        self.strokeWidth = strokeWidth
    }
    
    public init?(fill: String = "black", stroke: String = "black", strokeWidth: Double = 0, d: String) {
        self.fill = fill
        self.stroke = stroke
        self.strokeWidth = strokeWidth
        
        // Handle the path
        let parts = d.split{$0 == " "}.map(String.init)
        var partsIter = parts.makeIterator()
        while let current = partsIter.next() {
            switch current {
            case "M":
                guard let xStr = partsIter.next() else { return nil }
                guard let yStr = partsIter.next() else { return nil }
                guard let x = Double(xStr) else { return nil }
                guard let y = Double(yStr) else { return nil }
                self.pathElements.append(M(x: x, y: y))
            case "L":
                guard let xStr = partsIter.next() else { return nil }
                guard let yStr = partsIter.next() else { return nil }
                guard let x = Double(xStr) else { return nil }
                guard let y = Double(yStr) else { return nil }
                self.pathElements.append(L(x: x, y: y))
            case "C":
                var controlPoints: [Point] = []
                for _ in 0..<3 {
                    guard let xStr = partsIter.next() else { return nil }
                    guard let yStr = partsIter.next() else { return nil }
                    guard let x = Double(xStr) else { return nil }
                    guard let y = Double(yStr) else { return nil }
                    controlPoints.append(Point(x: x, y: y))
                }
                self.pathElements.append(C(controlPoints: controlPoints))
            case "Z":
                self.pathElements.append(Z())
            default:
                return nil
            }
        }
        
        // Shift to minimal box
        self.minimizePath()
    }
    
    public mutating func resize(percentWidth: Double, percentHeight: Double) {
        for i in 0..<self.pathElements.count {
            self.pathElements[i].resize(percentWidth: percentWidth, percentHeight: percentHeight)
        }
    }
    
    public mutating func resize(width: Double, height: Double) {
        let bboxOpt = self.boundingBox
        if let bbox = bboxOpt {
            let percentHeight = height/bbox.height
            let percentWidth = width/bbox.width
            self.resize(percentWidth: percentWidth, percentHeight: percentHeight)
        }
    }
    
    public mutating func move(dx: Double, dy: Double) {
        for i in 0..<self.pathElements.count {
            self.pathElements[i].move(dx: dx, dy: dy)
        }
    }
    
    /**
     Minimize the path by shiftng everything to the upper left.
     */
    public mutating func minimizePath() {
        let boxes = self.pathElements.map({$0.boundingBox})
        if let box = BoundingBox.of(boxes: boxes) {
            self.move(dx: -1*box.x, dy: -1*box.y)
        }
    }
}

/**
 Options for customizing how the SVG's are generated.
 */
public struct SVGOptions {
    /**
     How far apart should 'val |---| op |---| val' be.
     */
    public static var infixSpacing = 1.0
    
    /**
     How far apart should '1 |---| 2 |---| 3' be in 123.
     
     Also used for how far a decimal should be from the surrounding numbers.
     */
    public static var integerSpacing = 0.3
    
    public static var parethesesSpacing = 0.3
    
    public static var fractionBarThickness = 0.1
    public static var fractionSpacing = 1.0
}
/**
 Some utility functions for combining SVGs
 */
public struct SVGUtilities {
    /**
     How to align SVG's in operations.
     */
    public enum Alignment { case start, center, end }
    
    /**
     What direction to compose in
     */
    public enum Direction { case vertical, horizontal }
    
    /**
     Compose two or more svg's with the given alignment and direction
     */
    public static func compose(elements: [SVGElement], spacing: Double, alignment: Alignment = .end, direction: Direction = .horizontal) -> SVGElement {
        if(elements.count == 1) {
            let svgTemp = SVG(children: [elements[0]])
            svgTemp.minimizeSVG()
            return svgTemp
        } else if(elements.count == 0) {
            return SVG(children: [])
        }
        
        let svg = SVG(children: [])
        let bboxes = elements.map({$0.boundingBox!})
        
        switch direction {
        case .horizontal:
            // So we can align the base line
            let maxHeight = bboxes.map({$0.height}).max()!

            var currentX = 0.0
            for i in 0 ..< elements.count {
                // Account for alignments
                switch alignment {
                case .start:
                    svg.paste(path: elements[i], withTopLeftAt: Point(currentX, 0))
                case .center:
                    svg.paste(path: elements[i], withCenterLeftAt: Point(currentX, maxHeight/2))
                case .end:
                    svg.paste(path: elements[i], withBottomLeftAt: Point(currentX, maxHeight))
                }
                currentX += bboxes[i].width + spacing
            }
        case .vertical:
            // So we can line up centers
            let maxWidth = bboxes.map({$0.width}).max()!

            var currentY = 0.0
            for i in 0 ..< elements.count {
                // Account for alignments
                switch alignment {
                case .start:
                    svg.paste(path: elements[i], withTopLeftAt: Point(0, currentY))
                case .center:
                    svg.paste(path: elements[i], withCenterTopAt: Point(maxWidth/2, currentY))
                case .end:
                    svg.paste(path: elements[i], withTopLeftAt: Point(maxWidth-bboxes[i].width, currentY))
                }
                currentY += bboxes[i].height + spacing
            }
        }
        
        return svg
    }
    
    public static func formalParentheses(_ element: SVGElement) -> SVGElement {
        let bbox = element.boundingBox!
        var left = SVGFormalSymbols.getSymbol("(")!
        var right = SVGFormalSymbols.getSymbol(")")!
        let leftBB = left.boundingBox!
        left.scale(by: bbox.height/leftBB.height)
        right.scale(by: bbox.height/leftBB.height)
        return SVGUtilities.compose(elements: [left, element, right], spacing: SVGOptions.parethesesSpacing, alignment: .center, direction: .horizontal)
    }
    
    public static func svg(of str: String) -> SVGElement? {
        let numberPaths: [SVGPath?] = str.map({SVGFormalSymbols.getSymbol(String($0))})
        guard numberPaths as? [SVGPath] != nil else { return nil}
        return SVGUtilities.compose(elements: numberPaths as! [SVGPath], spacing: SVGOptions.integerSpacing, alignment: .end, direction: .horizontal)
    }
    
}
