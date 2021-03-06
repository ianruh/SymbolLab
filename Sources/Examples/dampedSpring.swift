import SymbolLab
import PythonKit
import SwiftBackend

func dampedMassSpring(withGui: Bool = true) {
    let m: Number = 1.0          // Mass
    let k: Number = 4.0          // Spring constant
    let b: Number = 0.4          // Damping parameter
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
        let plt = try Python.import("matplotlib.pyplot")
        let tpl  = try Python.import("termplotlib")
        let np = try Python.import("numpy")

        // Solve the system and extract the position and velocity
        let (values, errors, iterations) = try system.solveODE(at: tVals, using: SwiftBackend.self)
        var xVals = values.map({$0[x]!})
        var vVals = values.map({$0[v]!})

        tVals.popLast() // xVals and vVals has one less element than tVals

        let xarr = np.array(xVals)
        let varr = np.array(vVals)

        if(withGui) {
            plt.plot(xarr)
            plt.plot(varr)
            plt.show()

            print("If you did not see anything, try running with the '--no-gui' flag.")
        } else {
            let figure1 = tpl.figure()
            print("              ================== Position vs. Time ==================")
            figure1.plot(tVals, xarr)
            figure1.show()

            let figure2 = tpl.figure()
            print("\n\n              ================== Velocity vs. Time ==================")
            figure2.plot(tVals, varr)
            figure2.show()
        }

    } catch {
        print(error)
    }
}
