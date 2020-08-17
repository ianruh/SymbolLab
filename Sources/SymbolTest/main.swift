//
//  File.swift
//  
//
//  Created by Ian Ruh on 5/14/20.
//

import Foundation
import SymbolLab

let parser = Parser()
let nodeOpt: Node? = parser.parse(cString: "1+2-x/3 + 24^2 - 1/sin(x^(2-x))")
let system: System = [
    parser.parse(cString: "x+y+z")!,
    parser.parse(cString: "x+2")!,
    parser.parse(cString: "z^2-1")!
]

system.solve()

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
