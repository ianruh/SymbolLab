import XCTest
import SymbolLab
@testable import SwiftBackend

//[Assign(),
// Decimal(),
// Negative(),
// Add(),
// Subtract(),
// Multiply(),
// Divide(),
// Power(),
// Factorial(),
// Parentheses(),
// Derivative(),
// Integral(),
// Expand(),
// AbsoluteValue(),
// ErrorFunction(),

// Sin(),
// Cos(),
// Tan(),
// Sqrt(),
// Exp(),
// Log()]

final class SwiftBackendTests: XCTestCase {

    func assertNodesEqual(_ node1: Node?, _ node2: Node, _ alternatives: [String] = [], file: StaticString = #file, line: UInt = #line) {
        guard let node1n = node1 else {
            XCTFail("nil is not equal to \(node2)")
            return
        }
        if(alternatives.count > 0) {
            if(!alternatives.contains(node1n.description)) {
                XCTFail("The alternatives (\(alternatives)) do not include \(node1n.description)")
            }
        } else {
            XCTAssertEqual(node1n.description, node2.description)
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
        let result2 = Number(0)
        assertNodesEqual(SwiftBackend.diff(of: y, withRespectTo: x), result2)
    }

    func testDerivativeNumber() {
        let one = Number(1)
        let x = Variable("x")
        let result = Number(0)
        assertNodesEqual(SwiftBackend.diff(of: one, withRespectTo: x), result)
    }

    func testDerivativeDecimal() {
        let one = SymbolLab.Decimal(1.0)
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
        let result2 = Number(1)
        assertNodesEqual(SwiftBackend.diff(of: expr2, withRespectTo: x), result2)
    }

    func testDerivativeSub() {
        let x = Variable("x")
        let expr = x - x
        let result = Subtract([Number(1), Number(1)])
        assertNodesEqual(SwiftBackend.diff(of: expr, withRespectTo: x), result)

        let y = Variable("y")
        let expr2 = x - y
        let result2 = Number(1)
        assertNodesEqual(SwiftBackend.diff(of: expr2, withRespectTo: x), result2)

        let expr3 = y - x
        let result3 = -1*Number(1)
        assertNodesEqual(SwiftBackend.diff(of: expr3, withRespectTo: x), result3)
    }

    // TODO: Minimize the multiplication (part of overall simplification)
    func testDerivativeMultiply() {
        let x = Variable("x")
        let y = Variable("y")
        let expr = x*x
        let result = 2*x
        assertNodesEqual(SwiftBackend.diff(of: expr, withRespectTo: x), result, ["x*1+x*1"])

        let expr2 = x*y
        let result2 = y
        assertNodesEqual(SwiftBackend.diff(of: expr2, withRespectTo: x), result2, ["y*1"])

        let expr3 = 2*x + x*y
        let result3 = 2 + y
        assertNodesEqual(SwiftBackend.diff(of: expr3, withRespectTo: x), result3, ["2.0*1+y*1"])
    }

    func testDerivativeDivision() {
        let x = Variable("x")
        let y = Variable("y")

        let expr = x / 2
        let result =  Divide([Number(1), Number(2)])
        assertNodesEqual(SwiftBackend.diff(of: expr, withRespectTo: x), result, ["(1*2.0)/2.0^2"])

        let expr2 = x / (x + 1)
        let result2: Node = 1 / Power([(x+1), Number(2)])
        assertNodesEqual(SwiftBackend.diff(of: expr2, withRespectTo: x), result2, ["(1*(x+1.0)-1*x)/(x+1.0)^2"])

        let expr3 = (y+x)/(y-x)
        let result3 = 2*y / Power([(y-x), Number(2)])
        assertNodesEqual(SwiftBackend.diff(of: expr3, withRespectTo: x), result3, ["(1*(y-x)-(-1.0*1)*(y+x))/(y-x)^2"])
    }

    func testDerivativePower() {
        let x = Variable("x")

        let expr = Power([x, Number(2)])
        let result =  2*x
        assertNodesEqual(SwiftBackend.diff(of: expr, withRespectTo: x), result, ["((x^2*1)*2)/x"])

        let expr2 = Power([Number(2), x])
        let result2 = Power([Number(2), x]) * Log([Number(2)]) * Number(1)
        assertNodesEqual(SwiftBackend.diff(of: expr2, withRespectTo: x), result2, ["(2^x*1)*log(2)"])

        let expr3 = Power([(x+1), x])
        let result3 = (Log([x+1]) + x/(x+1))*Power([(x+1), x])
        assertNodesEqual(SwiftBackend.diff(of: expr3, withRespectTo: x), result3, ["(x+1.0)^x*((1*x)/(x+1.0)+1*log(x+1.0))"])
    }

    func testDerivativeSin() {
        let x = Variable("x")

        let expr = Sin([x])
        let result =  Cos([x])
        assertNodesEqual(SwiftBackend.diff(of: expr, withRespectTo: x), result, ["cos(x)*1"])

        let expr2 = Sin([Power([x, Number(2)])])
        let result2 = Cos([Power([x, Number(2)])])*2*x
        assertNodesEqual(SwiftBackend.diff(of: expr2, withRespectTo: x), result2, ["cos(x^2)*(((x^2*1)*2)/x)"])
    }

    func testDerivativeCos() {
        let x = Variable("x")

        let expr = Cos([x])
        let result =  -1*Sin([x])
        assertNodesEqual(SwiftBackend.diff(of: expr, withRespectTo: x), result, ["(-1.0*sin(x))*1"])

        let expr2 = Cos([Power([x, Number(2)])])
        let result2 = -1*Sin([Power([x, Number(2)])])*2*x
        assertNodesEqual(SwiftBackend.diff(of: expr2, withRespectTo: x), result2, ["(-1.0*sin(x^2))*(((x^2*1)*2)/x)"])
    }

    func testDerivativeTan() {
        let x = Variable("x")

        let expr = Tan([x])
        let result =  1/Power([Cos([x]), Number(2)])
        assertNodesEqual(SwiftBackend.diff(of: expr, withRespectTo: x), result, ["(1.0/cos(x)^2)*1"])

        let expr2 = Tan([Power([x, Number(2)])])
        let result2 = 1/Power([Cos([Power([x, Number(2)])]), Number(2)]) * 2 * x
        assertNodesEqual(SwiftBackend.diff(of: expr2, withRespectTo: x), result2, ["(1.0/cos(x^2)^2)*(((x^2*1)*2)/x)"])
    }

    func testDerivativeExp() {
        let x = Variable("x")

        let expr = Exp([x])
        let result =  Exp([x])
        assertNodesEqual(SwiftBackend.diff(of: expr, withRespectTo: x), result, ["exp(x)*1"])

        let expr2 = Exp([Power([x, Number(2)])])
        let result2 = Exp([Power([x, Number(2)])]) * 2 * x
        assertNodesEqual(SwiftBackend.diff(of: expr2, withRespectTo: x), result2, ["exp(x^2)*(((x^2*1)*2)/x)"])
    }

    func testDerivativeLog() {
        let x = Variable("x")

        let expr = Log([x])
        let result =  1/x
        assertNodesEqual(SwiftBackend.diff(of: expr, withRespectTo: x), result, ["(1.0/x)*1"])

        let expr2 = Log([Power([x, Number(2)])])
        let result2 = 1/Power([x, Number(2)]) * 2 * x
        assertNodesEqual(SwiftBackend.diff(of: expr2, withRespectTo: x), result2, ["(1.0/x^2)*(((x^2*1)*2)/x)"])
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
