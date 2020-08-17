//
//  File.swift
//  
//
//  Created by Ian Ruh on 6/14/20.
//

/**
 Options for customizing how the SVG's are generated.
 */
public struct SVGOptions {
    /**
     How far apart should 'val |---| op |---| val' be.
     */
    public static var infixSpacing = 0.33
    
    /**
     How far apart should '1 |---| 2 |---| 3' be in 123.
     
     Also used for how far a decimal should be from the surrounding numbers.
     */
    public static var integerSpacing = 0.1
    
    public static var parethesesSpacing = 0.2
    
    public static var fractionBarThickness = 0.1
    public static var fractionSpacing = 0.33
    public static var powerSpacing = 0.2
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
    
    public static func parentheses(_ element: SVGElement, using source: SVGSource) -> SVGElement {
        let bbox = element.boundingBox!
        var left = source.getSymbol("(")!
        var right = source.getSymbol(")")!
        let leftBB = left.boundingBox!
        left.scale(by: bbox.height/leftBB.height)
        right.scale(by: bbox.height/leftBB.height)
        return SVGUtilities.compose(elements: [left, element, right], spacing: SVGOptions.parethesesSpacing, alignment: .center, direction: .horizontal)
    }
    
    public static func svg(of str: String, using source: SVGSource) -> SVGElement? {
        let numberPaths: [SVGPath?] = str.map({source.getSymbol(String($0))})
        guard numberPaths as? [SVGPath] != nil else { return nil}
        return SVGUtilities.compose(elements: numberPaths as! [SVGPath], spacing: SVGOptions.integerSpacing, alignment: .end, direction: .horizontal)
    }
}
