//
//  File.swift
//  
//
//  Created by Ian Ruh on 5/14/20.
//

import Foundation
import SymbolLab
import SwiftPlot
import SVGRenderer
import SymEngineBackend

let parser = Parser()
var genOptions = GeneratorOptions()
genOptions.maxDepth = 3
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
    Derivative(),
    Log(),
]

// Define the system
let system: System = [
    parser.parse(cString: "ve-2000")!, // m/s
    parser.parse(cString: "mf-5000")!, // kg
    parser.parse(cString: "deltaV-ve*log(mz/mf)")!,
    parser.parse(cString: "mr-(mz/mf)")!,
]
print(system)

let mzVals = Array(stride(from: 5000, through: 90000.0, by: 100))

do {
    let (values, errors, iterations) = try system.solve(at: ["mz": mzVals], using: SymEngineBackend.self)
    let deltaVVals = values.map({$0["deltaV"]!})

    var svg_renderer: SVGRenderer = SVGRenderer()
    var lineGraph = LineGraph<Double,Double>(enablePrimaryAxisGrid: true)
    lineGraph.addSeries(mzVals, deltaVVals, label: "X Value", color: .lightBlue)
    lineGraph.plotTitle.title = "Initial Mass vs. DeltaV"
    lineGraph.plotLabel.xLabel = "Initial Mass (kg)"
    lineGraph.plotLabel.yLabel = "Delta V (m/s)"
    lineGraph.plotLineThickness = 3.0
    try lineGraph.drawGraphAndOutput(fileName: "/Users/ianruh/Downloads/graph", renderer: svg_renderer)
} catch {
    print(error)
    exit(1)
}
