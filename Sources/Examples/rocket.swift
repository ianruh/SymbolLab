import SymbolLab
import PythonKit
import SwiftBackend

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
        let plt = try Python.import("matplotlib.pyplot")
        let np = try Python.import("numpy")

        let (values, errors, iterations) = try system.solve(at: [mz: mzVals], using: SwiftBackend.self)
        let deltaVVals = values.map({$0[deltaV]!})

        let dvarr = np.array(deltaVVals)
        plt.plot(dvarr)
        plt.show()

    } catch {
        print(error)
    }
}