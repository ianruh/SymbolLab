import SymbolLab
import SwiftPlot
import SVGRenderer
import SymEngineBackend

func dampedMassSpring() {
    let m: Decimal = 1.0          // Mass
    let k: Decimal = 4.0          // Spring constant
    let b: Decimal = 0.4          // Damping parameter
    let ff = Variable("ff")                 // Damping force
    let fs = Variable("fs")                 // Spring force
    let x = Variable("x", initialValue: 2)  // Mass position
    let v = Variable("v", initialValue: 0)  // Mass velocity
    let t = Variable("t")                   // Time

    let system: System = [
        ff ≈ -1.0 * b*v,                                        // Damping force
        fs ≈ -0.5 * (k*x),                                      // Spring force
        Derivative(of: v, wrt: t) ≈ (fs + ff)/m,
        Derivative(of: x, wrt: t) ≈ v
    ]

    var tVals = Array(stride(from: 0.0, through: 20.0, by: 0.01)) // Time values to use

    do {
        // Solve the system and extract the position and velocity
        let (values, errors, iterations) = try system.solve(at: ["t": tVals], using: SymEngineBackend.self)
        var xVals = values.map({$0["x"]!})
        var vVals = values.map({$0["v"]!})

        tVals.popLast() // xVals and vVals has one less element than tVals

        var svg_renderer: SVGRenderer = SVGRenderer()
        var lineGraph = LineGraph<Double,Double>(enablePrimaryAxisGrid: true)
        lineGraph.addSeries(tVals, xVals, label: "Mass Position", color: .lightBlue)
        lineGraph.addSeries(tVals, vVals, label: "Mass Velocity", color: .orange)
        lineGraph.plotTitle.title = "Damped Mass on Spring"
        lineGraph.plotLabel.xLabel = "Time (s)"
        lineGraph.plotLabel.yLabel = "Position (m)"
        lineGraph.plotLabel.y2Label = "Velocity (m/s)"
        lineGraph.plotLineThickness = 3.0
        try lineGraph.drawGraphAndOutput(fileName: "/Users/ianruh/Downloads/dampedspring", renderer: svg_renderer)
    } catch {
        print(error)
    }
}
