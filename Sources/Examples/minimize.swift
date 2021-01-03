import SymbolLab
import SwiftBackend

func minimizeExample() {
    let x = Variable("x")
    let y = Variable("y")
    // let z = Variable("z")

    let system: System = [
        x**2 + y**2 ≈ 136
    ]

    do {
        let cost: Node = 5*x - 3*y
        let (values, errors, iterations) = try system.minimize(cost, using: SwiftBackend.self)
        print("Values: \(values)")
    } catch {
        print(error)
    }
}
