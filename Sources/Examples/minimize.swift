import SymbolLab
import SwiftBackend

func minimizeExample() {
    let x = Variable("x")
    let y = Variable("y")
    let z = Variable("z")

    print("Simplified: \((x*x*x).simplify())")

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
