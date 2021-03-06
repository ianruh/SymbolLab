import XCTest
import SwiftBackend
@testable import SymbolLab

/// Note: These tested only what their name suggests as I was writing them. However, as the simplification code
/// is more complex, they essentially all test more than just one behavior, but they do atleast test what their
/// name says.
final class SymbolLabTests: XCTestCase {
    func assertNodesEqual(_ node1: Node?, _ node2: Node, _ alternatives: [String] = [], file: StaticString = #file, line: UInt = #line) {
        if let node1n = node1 {
            let n1s = node1n.simplify()
            let n2s = node2.simplify()
            if(!(n1s == n2s)) {
                XCTFail("'\(n1s)' is not equal to '\(n2s)'. Simplified from '\(node1n)' and '\(node2)'.")
            } else {
                XCTAssert(true)
            }
        } else {
            XCTFail("node1 was nil")
        }

    }

    func testLeveling() {
       let x = Variable("x")
       let y = Variable("y")
       let exp1 = x*x*x
       let res1 = x**3
       assertNodesEqual(exp1, res1)

       let exp2 = x+y+x
       let res2 = 2*x + y
       assertNodesEqual(exp2, res2)

       let exp3 = (x*x)*(x*x)
       let res3 = x**4
       assertNodesEqual(exp3, res3)

       let exp4 = (x*x)*(x*x)+(y+y+(y+y))
       let res4 = x**4 + 4*y
       assertNodesEqual(exp4, res4)
    }

    func testRationalSimplifying() {
        let x = Variable("x")
        let y = Variable("y")
        let z = Variable("z")
        let a = Variable("a")
        let b = Variable("b")
        let c = Variable("c")

        let exp1 = x/(y/z)
        let res1 = (x*z)/y
        assertNodesEqual(exp1, res1)

        let exp2 = (x/y)/z
        let res2 = x/(y*z)
        assertNodesEqual(exp2, res2)

        let exp3 = (x/z)/(y/z)
        let res3 = (x*z)/(z*y)
        assertNodesEqual(exp3, res3)

        let exp4 = x*(y/z)*(a/b)*c
        let res4 = (x*y*a*c)/(z*b)
        assertNodesEqual(exp4, res4)
    }

    func testNumberCombining() {
        let one: Number = Number(1.0)
        let two: Number = Number(2.0)
        let three: Number = Number(3.0)

        let exp1 = one+two+three
        let res1 = Number(6)
        assertNodesEqual(exp1, res1)

        let exp2 = three-two-one
        let res2 = Number(0)
        assertNodesEqual(exp2, res2)

        let exp3 = three*two*one
        let res3 = Number(6.0)
        assertNodesEqual(exp3, res3)

        let exp4 = Divide(three,two)
        let res4 = Number(1.5)
        assertNodesEqual(exp4, res4)

        let exp5 = Power(two, three)
        let res5 = Number(8.0)
        assertNodesEqual(exp5, res5)
    }

    func testEquality() {
        let one: Number = Number(1.0)
        let two: Number = Number(2.0)
        let three: Number = Number(3.0)
        let x = Variable("x")
        let y = Variable("y")
        let z = Variable("z")

        assertNodesEqual(x, x)

        assertNodesEqual(x+x, x+x)

        assertNodesEqual(y-x, -1*x+y)

        assertNodesEqual(z*y*x, x*y*z)

        assertNodesEqual(one, one)

        assertNodesEqual(one*three, three)
    }

    func testComparable() {
        let x = Variable("x")
        let y = Variable("y")

        XCTAssertTrue(x < y)

        XCTAssertTrue(-1*x < y)
    }

    func testCombineLike() {
        let x = Variable("x")
        let y = Variable("y")

        assertNodesEqual(x*x, Power(x, Number(2)))
        assertNodesEqual(x*Power(x, Number(2)), Power(x, Number(3)))
        assertNodesEqual(x*Power(x, y), Power(x, Number(1) + y))
        assertNodesEqual(x*x*x, Power(x, Number(3)))

        assertNodesEqual(x+x+x, 3*x)
    }

    func testIdentities() {
        let x = Variable("x")

        assertNodesEqual(Number(0)*x, Number(0))
        assertNodesEqual(Number(1)*x, x)

        assertNodesEqual(Number(0)+x, x)
    }

    func testNodeHashable() {
        let x = Variable("x")
        let y = Variable("y")

        let one = Number(1)
        let two = Number(2)

        let sin = Sin(x)
        let cos = Cos(x)
        let der = Derivative(of: x,  wrt: y)
        let der2 = Derivative(of: y,  wrt: x)

        var dict: Dictionary<Node, Bool> = [:]
        dict[x] = true
        dict[one] = true
        dict[sin] = true
        dict[der] = true

        XCTAssertNil(dict[y])
        XCTAssertNil(dict[two])
        XCTAssertNil(dict[cos])
        XCTAssertNil(dict[der2])

        XCTAssertNotNil(dict[x])
        XCTAssertNotNil(dict[one])
        XCTAssertNotNil(dict[sin])
        XCTAssertNotNil(dict[der])
    }

    func testReplace() {
        let x = Variable("x")
        let y = Variable("y")
        let z = Variable("z")

        let exp1 = y+y
        let res1 = (x+x).replace(x, with: y)
        assertNodesEqual(exp1, res1)

        let exp2 = y
        let res2 = (x*x).replace(x*x, with: y)
        assertNodesEqual(exp2, res2)

        let exp3 = z
        let res3 = Derivative(of: x, wrt: y).replace(Derivative(of: x, wrt: y), with: z)
        assertNodesEqual(exp3, res3)
    }

    func testDerivativeSolvingOne() {
        let x = Variable("x")
        let y = Variable("y")

        let system: System = [
            Derivative(of: x, wrt: y) ≈ 2*x,
            x ≈ 4
        ]

        do {
            let (values, errors, iterations) = try system.solve(using: SwiftBackend.self)
            let res = values[Derivative(of: x, wrt: y)]
            let expect = 8.0
            if let resno = res {
                XCTAssertEqual(resno, expect, accuracy: 0.00001)
            } else {
                XCTFail("Unexpectedly found nil in the solution to the system.")
            }
        } catch {
            XCTFail("An unexpected error was thrown while solving the system: \(error)")
        }
    }

    func testDerivativeSolvingTwo() {
        // This test is adapted from the damped spring example
        let m: Number = 1.0          // Mass
        let k: Number = 4.0          // Spring constant
        let b: Number = 0.4          // Damping parameter
        let ff = Variable("ff")                 // Damping force
        let fs = Variable("fs")                 // Spring force
        let x = Variable("x")  // Mass position
        let v = Variable("v")  // Mass velocity
        let t = Variable("t")                   // Time

        let system: System = [
            ff ≈ -1.0 * b*v,                                        // Damping force
            fs ≈ -0.5 * (k*x),                                      // Spring force
            Derivative(of: v, wrt: t) ≈ (fs + ff)/m,
            Derivative(of: x, wrt: t) ≈ v,
            x ≈ 2.0,
            v ≈ 0.0
        ]

        do {
            let (values, errors, iterations) = try system.solve(using: SwiftBackend.self)

            XCTAssertEqual(values[ff]!, 0.0, accuracy: 0.00001)
            XCTAssertEqual(values[fs]!, -4.0, accuracy: 0.00001)
            XCTAssertEqual(values[Derivative(of: v, wrt: t)]!, -4.0, accuracy: 0.00001)
            XCTAssertEqual(values[Derivative(of: x, wrt: t)]!, 0.0, accuracy: 0.00001)
        } catch {
            XCTFail("An unexpected error was thrown while solving the system: \(error)")
        }
    }

    func testMinimizationOne() {
        let x = Variable("x")
        let y = Variable("y")

        let system: System = [
            x + y ≈ 2
        ]

        do {
            let cost: Node = -1*x*y
            let (values, errors, iterations) = try system.minimize(cost, using: SwiftBackend.self)
            
            XCTAssertEqual(values[x]!, 1.0, accuracy: 0.0001)
            XCTAssertEqual(values[y]!, 1.0, accuracy: 0.0001)

        } catch {
            XCTFail("An unexpected error occured while minimizing the systems: \(error)")
        }
    }

    func testMinimizationTwo() {
        // https://en.wikipedia.org/wiki/Test_functions_for_optimization
        // Booth Function
        let x = Variable("x")
        let y = Variable("y")

        let system: System = []

        do {
            let cost: Node = (x + 2*y - 7)**2 + (2*x + y - 5)**2
            let (values, errors, iterations) = try system.minimize(cost, using: SwiftBackend.self)

            XCTAssertEqual(values[x]!, 1.0, accuracy: 0.0001)
            XCTAssertEqual(values[y]!, 3.0, accuracy: 0.0001)

        } catch {
            XCTFail("An unexpected error occured while minimizing the systems: \(error)")
        }
    }

    // func testMinimizationThree() {
    //     // https://en.wikipedia.org/wiki/Test_functions_for_optimization
    //     // Easom Function
    //     let x = Variable("x")
    //     let y = Variable("y")

    //     let system: System = []

    //     do {
    //         let cost: Node = -1*Cos(x)*Cos(y)*Exp(-1*((x-Number(Double.pi))**2+(y-Number(Double.pi))**2))
    //         let (values, errors, iterations) = try system.minimize(cost, using: SwiftBackend.self)

    //         XCTAssertEqual(values[x]!, Double.pi, accuracy: 0.0001)
    //         XCTAssertEqual(values[y]!, Double.pi, accuracy: 0.0001)

    //     } catch {
    //         XCTFail("An unexpected error occured while minimizing the systems: \(error)")
    //     }
    // }

    static var allTests = [
        ("Leveling Tests", testLeveling),
        ("Rational Simplifying Tests", testRationalSimplifying),
        ("Number Combining", testNumberCombining),
        ("Equality", testEquality),
        ("Comparable", testComparable),
        ("Combine Like", testCombineLike),
        ("Identities", testIdentities),
        ("Hashable", testNodeHashable),
        ("Test Replace", testReplace),
        ("Test Derivative Solving #1", testDerivativeSolvingOne),
        ("Test Derivative Solving #2", testDerivativeSolvingTwo),
        ("Test Minimization #1", testMinimizationOne),
        ("Test Minimization #2", testMinimizationTwo),
        // ("Test Minimization #3", testMinimizationThree), // Known to be broken currently
    ]
}
