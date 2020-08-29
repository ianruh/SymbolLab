//
//  File.swift
//
//
//  Created by Ian Ruh on 7/3/20.
//

import Foundation
//import ArgumentParser
import SymbolLab
//
//struct Generate: ParsableCommand {
////    @Flag(help: "Include a counter with each repetition.")
////    var includeCounter = false
//
//    @Option(name: .shortAndLong, help: "Number of samples to generate.")
//    var count: Int?
//
//    @Option(name: .shortAndLong, help: "Depth of the trees to generate.")
//    var depth: Int?
//
//    @Argument(help: "Label file name")
//    var labelFile: String
//
//    @Argument(help: "SVG Directory")
//    var svgDirectory: String
//
//    @Argument(help: "JPG Directory")
//    var jpgDirectory: String
//
//    mutating func run() throws {
//        print("Whate the  fuck")
//        let sampleCount = count ?? 10
//        let treeDepth = depth ?? 4
//
//        var genOptions = GeneratorOptions()
//        genOptions.maxDepth = 3
//        genOptions.operations.assignments.maxChain = 0
//        genOptions.operations.list = [
//            Decimal([P,P]),
//            Negative([P]),
//            Add([P,P]),
//            Subtract([P,P]),
//            Multiply([P,P]),
//            Divide([P,P]),
//            Power([P,P]),
//            Parentheses([P]),
//            Sin([P]),
//            Cos([P]),
//            Tan([P]),
//        ]
//
//        var nodes: [Node] = []
//        for i in 0..<sampleCount {
//            nodes.append(GeneratorUtilities.randomNode(&genOptions))
//        }
//
//        let svgSource = SVGFormalSymbols()
//
//        var tokenMap: [String: Int] = [:]
//        do {
//            tokenMap = try KerasYOLOWriter.write(nodes: nodes, labelFile: labelFile, svgDirectory: svgDirectory, jpgDirectory: jpgDirectory, usingSVGSource: svgSource)
//        } catch {
//            print("Unexpected error: \(error).")
//        }
//
//        print("Token Map:\n\(tokenMap)")
//    }
//}
//
//Generate.main()

let sampleCount =  400
let treeDepth =  5

var genOptions = GeneratorOptions()
genOptions.maxDepth = treeDepth
genOptions.operations.assignments.maxChain = 0
genOptions.operations.list = [
    Decimal(),
    Negative(),
    Add(),
    Subtract(),
    Multiply(),
    Divide(),
    Power(),
    Parentheses(),
    Sin(),
    Cos(),
    Tan(),
    AbsoluteValue()
]

var nodes: [Node] = []
for _ in 0..<sampleCount {
    nodes.append(GeneratorUtilities.randomNode(&genOptions))
}

let svgSource = SVGFormalSymbols()

do {
    try KerasYOLOWriter.write(nodes: nodes, labelFile: "scratch/labels.txt", classesFile: "scratch/classes.txt", svgDirectory: "scratch/svgs", jpgDirectory: "scratch/jpgs", usingSVGSource: svgSource, size: 224)
} catch {
    print("Unexpected error: \(error).")
}