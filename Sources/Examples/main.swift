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

massSpring()

func massSpring() {
    let m: SymbolLab.Decimal = 1.0 // Mass
    let k: SymbolLab.Decimal = 1.0 // Spring constant
    let x = Variable("x", initialValue: 2)
    let v = Variable("v", initialValue: 0)
    let t = Variable("t")

    let system: System = [
        Derivative(of: v, wrt: t) ≈ -0.5 * (k*x)/m,
        Derivative(of: x, wrt: t) ≈ v
    ]

    var tVals = Array(stride(from: 0.0, through: 10.0, by: 0.05))

    do {
        let (values, errors, iterations) = try system.solve(at: ["t": tVals], using: SymEngineBackend.self)
        var xVals = values.map({$0["x"]!})

        tVals.popLast() // xVals has one less element than tVals

        var svg_renderer: SVGRenderer = SVGRenderer()
        var lineGraph = LineGraph<Double,Double>(enablePrimaryAxisGrid: true)
        lineGraph.addSeries(tVals, xVals, label: "X Value", color: .lightBlue)
        lineGraph.plotLineThickness = 3.0
        try lineGraph.drawGraphAndOutput(fileName: "/Users/ianruh/Downloads/odespring", renderer: svg_renderer)
    } catch {
        print(error)
        exit(1)
    }
}

func simpleODE() {
    let x = Variable("x", initialValue: 1)
    let t = Variable("t")
    let system: System = [
        Derivative(of: x, wrt: t) ~ -0.2 * x
    ]

    let tVals = [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]

    do {
        let (values, errors, iterations) = try system.solve(at: ["t": tVals], using: SymEngineBackend.self)
        var xVals = values.map({$0["x"]!})
        xVals.append(0)

        var svg_renderer: SVGRenderer = SVGRenderer()
        var lineGraph = LineGraph<Double,Double>(enablePrimaryAxisGrid: true)
        lineGraph.addSeries(tVals, xVals, label: "X Value", color: .lightBlue)
        lineGraph.plotLineThickness = 3.0
        try lineGraph.drawGraphAndOutput(fileName: "/Users/ianruh/Downloads/ode", renderer: svg_renderer)
    } catch {
        print(error)
        exit(1)
    }
}

func rocket() {
    let ve: Variable = "ve"
    let mf: Variable = "mf"
    let deltaV: Variable = "deltaV"
    let mz: Variable = "mz"
    let mr: Variable = "mr"

    let system: System = [
        ve ~ 2000,
        mf ~ 5000,
        deltaV ~ ve*Log(mz/mf),
        mr ~ mz/mf
    ]

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
}