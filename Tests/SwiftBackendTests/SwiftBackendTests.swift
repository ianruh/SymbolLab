import XCTest
import SymbolLab
@testable import SwiftBackend

final class SwiftBackendTests: XCTestCase {

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

    func testDerivativeAssign() {
        let x = Variable("x")
        let assignment = Assign([Number(2), x])
        XCTAssertNil(SwiftBackend.diff(of: assignment, withRespectTo: x))
    }

    func testDerivativeVariable() {
        let x = Variable("x")
        let result = Number(1)
        assertNodesEqual(SwiftBackend.diff(of: x, withRespectTo: x), result)

        let y = Variable("y")
        let result2 = Derivative(of: y, wrt: x)
        assertNodesEqual(SwiftBackend.diff(of: y, withRespectTo: x), result2)
    }

    func testDerivativeNumber() {
        let one = Number(1)
        let x = Variable("x")
        let result = Number(0)
        assertNodesEqual(SwiftBackend.diff(of: one, withRespectTo: x), result)
    }

    func testDerivativeDecimal() {
        let one = SymbolLab.Number(1.0)
        let x = Variable("x")
        let result = Number(0)
        assertNodesEqual(SwiftBackend.diff(of: one, withRespectTo: x), result)
    }

    func testDerivativeNegative() {
        let x = Variable("x")
        let nx = -1*x
        let result = -1*Number(1)
        assertNodesEqual(SwiftBackend.diff(of: nx, withRespectTo: x), result)
    }

    func testDerivativeAdd() {
        let x = Variable("x")
        let expr = x + x
        let result = Add([Number(1), Number(1)])
        assertNodesEqual(SwiftBackend.diff(of: expr, withRespectTo: x), result)

        let y = Variable("y")
        let expr2 = x + y
        let result2 = Number(1) + Derivative(of: y, wrt: x)
        assertNodesEqual(SwiftBackend.diff(of: expr2, withRespectTo: x), result2)
    }

    func testDerivativeSub() {
        let x = Variable("x")
        let expr = x - x
        let result = Subtract([Number(1), Number(1)])
        assertNodesEqual(SwiftBackend.diff(of: expr, withRespectTo: x), result)

        let y = Variable("y")
        let expr2 = x - y
        let result2 = Number(1) - Derivative(of: y, wrt: x)
        assertNodesEqual(SwiftBackend.diff(of: expr2, withRespectTo: x), result2)

        let expr3 = y - x
        let result3 = Derivative(of: y, wrt: x) - Number(1)
        assertNodesEqual(SwiftBackend.diff(of: expr3, withRespectTo: x), result3)
    }

    // TODO: Minimize the multiplication (part of overall simplification)
    func testDerivativeMultiply() {
        let x = Variable("x")
        let y = Variable("y")
        let expr = x*x
        let result = 2*x
        assertNodesEqual(SwiftBackend.diff(of: expr, withRespectTo: x), result)

        let expr2 = x*y
        let result2 = x*Derivative(of: y, wrt: x) + y
        assertNodesEqual(SwiftBackend.diff(of: expr2, withRespectTo: x), result2)

        let expr3 = 2*x + x*y
        let result3 = 2 + x*Derivative(of: y, wrt: x) + y
        assertNodesEqual(SwiftBackend.diff(of: expr3, withRespectTo: x), result3)
    }

    func testDerivativeDivision() {
        let x = Variable("x")
        let y = Variable("y")

        let expr = x / 2
        let result =  Number(0.5)
        assertNodesEqual(SwiftBackend.diff(of: expr, withRespectTo: x), result)

        let expr2 = x / (x + 1)
        let result2: Node = 1 / Power([(x+1), Number(2)])
        assertNodesEqual(SwiftBackend.diff(of: expr2, withRespectTo: x), result2)

        let expr3 = (y+x)/(y-x)
        let result3 = ((y-x)*(Derivative(of: y, wrt: x)+1) - (y+x)*(Derivative(of: y, wrt: x)-1)) / Power([(y-x), Number(2)])
        assertNodesEqual(SwiftBackend.diff(of: expr3, withRespectTo: x), result3)
    }

    func testDerivativePower() {
        let x = Variable("x")

        let expr = Power([x, Number(2)])
        let result = 2*x
        assertNodesEqual(SwiftBackend.diff(of: expr, withRespectTo: x), result)

        let expr2 = Power([Number(2), x])
        let result2 = Power([Number(2), x]) * Log([Number(2)]) * Number(1)
        assertNodesEqual(SwiftBackend.diff(of: expr2, withRespectTo: x), result2)

        let expr3 = Power([(x+1), x])
        let result3 = (Log([x+1]) + x/(x+1))*Power([(x+1), x])
        assertNodesEqual(SwiftBackend.diff(of: expr3, withRespectTo: x), result3)
    }

    func testDerivativeSin() {
        let x = Variable("x")

        let expr = Sin([x])
        let result =  Cos([x])
        assertNodesEqual(SwiftBackend.diff(of: expr, withRespectTo: x), result)

        let expr2 = Sin([Power([x, Number(2)])])
        let result2 = Cos([Power([x, Number(2)])])*2*x
        assertNodesEqual(SwiftBackend.diff(of: expr2, withRespectTo: x), result2)
    }

    func testDerivativeCos() {
        let x = Variable("x")

        let expr = Cos([x])
        let result =  -1*Sin([x])
        assertNodesEqual(SwiftBackend.diff(of: expr, withRespectTo: x), result)

        let expr2 = Cos([Power([x, Number(2)])])
        let result2 = -1*Sin([Power([x, Number(2)])])*2*x
        let simp = SwiftBackend.diff(of: expr2, withRespectTo: x)!.simplify()
        assertNodesEqual(SwiftBackend.diff(of: expr2, withRespectTo: x), result2)
    }

    func testDerivativeTan() {
        let x = Variable("x")

        let expr = Tan([x])
        let result =  1/Power([Cos([x]), Number(2)])
        assertNodesEqual(SwiftBackend.diff(of: expr, withRespectTo: x), result)

        let expr2 = Tan([Power([x, Number(2)])])
        let result2 = 1/Power([Cos([Power([x, Number(2)])]), Number(2)]) * 2 * x
        assertNodesEqual(SwiftBackend.diff(of: expr2, withRespectTo: x), result2)
    }

    func testDerivativeExp() {
        let x = Variable("x")

        let expr = Exp([x])
        let result =  Exp([x])
        assertNodesEqual(SwiftBackend.diff(of: expr, withRespectTo: x), result)

        let expr2 = Exp([Power([x, Number(2)])])
        let result2 = Exp([Power([x, Number(2)])]) * 2 * x
        assertNodesEqual(SwiftBackend.diff(of: expr2, withRespectTo: x), result2)
    }

    func testDerivativeLog() {
        let x = Variable("x")

        let expr = Log([x])
        let result =  1/x
        assertNodesEqual(SwiftBackend.diff(of: expr, withRespectTo: x), result)

        let expr2 = Log([Power([x, Number(2)])])
        let result2 = 1/Power([x, Number(2)]) * 2 * x
        assertNodesEqual(SwiftBackend.diff(of: expr2, withRespectTo: x), result2)
    }

    static var allTests = [
        ("Derivative Assign Test", testDerivativeAssign),
        ("Derivative Variable Test", testDerivativeVariable),
        ("Derivative Number Test", testDerivativeNumber),
        ("Derivative Decimal Test", testDerivativeDecimal),
        ("Derivative Add Test", testDerivativeAdd),
        ("Derivative Subtract Test", testDerivativeSub),
        ("Derivative Multiply Test", testDerivativeMultiply),
        ("Derivative Division Test", testDerivativeDivision),
        ("Derivative Power Test", testDerivativePower),
        ("Derivative Sin Test", testDerivativeSin),
        ("Derivative Cos Test", testDerivativeCos),
        ("Derivative Tan Test", testDerivativeTan),
        ("Derivative Exp Test", testDerivativeExp),
        ("Derivative Log Test", testDerivativeLog),
    ]
}
