import SymbolLab
import SwiftBackend

func minimizeExample() {
    let x = Variable("x")
    // let y = Variable("y")
    // let z = Variable("z")

    let expr2 = Cos([Power([x, Number(2)])])
    let result2 = -1*Sin([Power([x, Number(2)])])*2*x
    let der = SwiftBackend.diff(of: expr2, withRespectTo: x)!
    let simp = der.simplify()

    // let system: System = [
    //     x + y ≈ 0,
    //     x**3 + z ≈ 1
    // ]

    // do {
    //     let cost: Node = x*y
    //     let (values, errors, iterations) = try system.minimize(cost, using: SwiftBackend.self)
    //     print("Values: \(values)")
    // } catch {
    //     print(error)
    // }
}
