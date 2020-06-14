//
//  File.swift
//  
//
//  Created by Ian Ruh on 5/14/20.
//

import Foundation
import SymbolLab


//Parser.parseCString("1+211*132^s/(yzt-3*2)-3.1415")
//let parser = Parser()
//let nodeOpt: Node? = parser.parseCString("x-2*3/3-1")
//let nodeOpt: Node? = parser.parse(cString: "d(sin(x^(2-x)),x)")

//if let node = nodeOpt {
//    print(node.symbol)
//} else {
//    print("Node is nil")
//}

//let str =  "1+2-2(3*6)"
//var options = GeneratorOptions()
//options.removeFunctions()
//options.maxDepth = 3
//options.operations.list = [Negative([P]), Decimal([P,P]), Add([P,P]), Subtract([P,P]), Multiply([P,P]), Divide([P,P])]
//let node: Node = GeneratorUtilities.randomNode(&options)
//let str = node.description
//print("Generated Description: \(str)")
//let nodeOpt = parser.parse(cString: str)
//print("Parsed Description:    \(nodeOpt == nil ? "nil": nodeOpt!.description)")
//print("Parsed Latex:          \(nodeOpt == nil ? "nil": nodeOpt!.latex)")

//try SVGSymbols.integral.writeToDisk(path: "/Users/ianruh/Dev/SymbolLab/integral.svg")

//let path = SVGPath(d: pathString)
//if let p = path {
//    let svg = SVG(width: 10, height: 10, children: [p])
//    try svg.writeToDisk(path: "/Users/ianruh/Downloads/img.svg")
////    p.move(dx: -3.71875, dy: 3.765625)
//    print(p)
//} else {
//    print("failed")
//}

//let svg = SVG(width: 100, height: 100, children: [])
//let a = SVGFormalSymbols.getSymbol("a")!
//let b = SVGFormalSymbols.getSymbol("b")!
//let sev = SVGFormalSymbols.getSymbol("7")!
//svg.paste(path: a, withBottomLeftAt: Point(0, 4))
//svg.paste(path: b, withBottomLeftAt: Point(a.boundingBox!.width, 4))
//svg.paste(path: sev, withBottomLeftAt: Point(a.boundingBox!.width+b.boundingBox!.width, 4))

let parser = Parser()
let nodeOpt: Node? = parser.parse(cString: "1+2-x/3 + 24^2 - 1/sin(x^(2-x))")
guard let node = nodeOpt else {
    print("Couldn't parse string")
    exit(1)
}

let svgOpt = node.formalSVG
guard let svg = svgOpt else {
    print("Failed to get SVG")
    exit(1)
}
try svg.writeToDisk(path: "/Users/ianruh/Downloads/img.svg")
