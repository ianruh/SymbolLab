//
//  File.swift
//  
//
//  Created by Ian Ruh on 5/14/20.
//

import Foundation
import SymbolLab

let parser = Parser()
var genOptions = GeneratorOptions()
genOptions.maxDepth = 3
genOptions.operations.assignments.maxChain = 0

genOptions.operations.list = [
    Decimal([P,P]),
    Negative([P]),
    Add([P,P]),
    Subtract([P,P]),
    Multiply([P,P]),
    Divide([P,P]),
    Power([P,P]),
    Parentheses([P]),
    Sin([P]),
    Cos([P]),
    Tan([P]),
//    Asin([P]),
//    Acos([P]),
//    Atan([P]),
]

let x = Variable("x")
let y = Variable("y")
let z = Variable("z")
//
//let system: System = [
//    x+(1 as Number)
//
//]

let system: System = [
    parser.parse(cString: "f-10")!,
    parser.parse(cString: "m-5")!,
    parser.parse(cString: "f-m*a")!,
    parser.parse(cString: "x^2+sin(f)-cos(x)/a^7")!,
]
//let system: System = [
//    GeneratorUtilities.randomNode(&genOptions),
//    GeneratorUtilities.randomNode(&genOptions),
//    GeneratorUtilities.randomNode(&genOptions),
//    GeneratorUtilities.randomNode(&genOptions),
//    GeneratorUtilities.randomNode(&genOptions),
//    GeneratorUtilities.randomNode(&genOptions),
//    parser.parse(cString: "cos(sin(b)^358-cos(53-a))")!
//]
print(system)

//try print(system.solve(guess: ["z": 1.5, "x": -2.5, "y": 1.5], maxIterations: 100))
try print(system.solve())

func writeSVG() throws {
    let parser = Parser()
    let nodeOpt: Node? = parser.parse(cString: "1+2-x/3 + 24^2 - 1/sin(x^(2-x))")

    guard let node = nodeOpt else {
        print("Couldn't parse string")
        exit(1)
    }

    let svgOpt = node.svg(using: SVGFormalSymbols())
    guard let svg = svgOpt else {
        print("Failed to get SVG")
        exit(1)
    }
    try svg.writeToDisk(path: "/Users/ianruh/Downloads/img.svg")
}
