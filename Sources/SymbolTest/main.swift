//
//  File.swift
//  
//
//  Created by Ian Ruh on 5/14/20.
//

import Foundation
import SymbolLab


//Parser.parseCString("1+211*132^s/(yzt-3*2)-3.1415")
let parser = Parser()
//let nodeOpt: Node? = parser.parseCString("x-2*3/3-1")
//let nodeOpt: Node? = parser.parse(cString: "d(sin(x^(2-x)),x)")

//if let node = nodeOpt {
//    print(node.symbol)
//} else {
//    print("Node is nil")
//}

//let str =  "1+2-2(3*6)"
var options = GeneratorOptions()
options.removeFunctions()
options.maxDepth = 3
//options.operations.list = [Negative([P]), Decimal([P,P]), Add([P,P]), Subtract([P,P]), Multiply([P,P]), Divide([P,P])]
let node: Node = GeneratorUtilities.randomNode(&options)
let str = node.description
print("Generated Description: \(str)")
let nodeOpt = parser.parse(cString: str)
print("Parsed Description:    \(nodeOpt == nil ? "nil": nodeOpt!.description)")
print("Parsed Latex:          \(nodeOpt == nil ? "nil": nodeOpt!.latex)")

//try SVGSymbols.integral.writeToDisk(path: "/Users/ianruh/Dev/SymbolLab/integral.svg")
