import XCTest
@testable import SymbolLab

final class SymbolLabTests: XCTestCase {
    func testLeveling() {
       let x = Variable("x")
       let y = Variable("y")
       let exp1 = x*x*x
       let res1 = "x*x*x"
       XCTAssertEqual(exp1.simplify().description, res1)

       let exp2 = x+y+x
       let res2 = "x+x+y"
       XCTAssertEqual(exp2.simplify().description, res2)

       let exp3 = (x*x)*(x*x)
       let res3 = "x*x*x*x"
       XCTAssertEqual(exp3.simplify().description, res3)

       let exp4 = (x*x)*(x*x)+(y+y+(y+y))
       let res4 = "x*x*x*x+y+y+y+y"
       XCTAssertEqual(exp4.simplify().description, res4)
    }

    func testRationalSimplifying() {
        let x = Variable("x")
        let y = Variable("y")
        let z = Variable("z")
        let a = Variable("a")
        let b = Variable("b")
        let c = Variable("c")

        let exp1 = x/(y/z)
        let res1 = "(x*z)/y"
        XCTAssertEqual(exp1.simplify().description, res1)

        let exp2 = (x/y)/z
        let res2 = "x/(y*z)"
        XCTAssertEqual(exp2.simplify().description, res2)

        let exp3 = (x/z)/(y/z)
        let res3 = "(x*z)/(z*y)"
        XCTAssertEqual(exp3.simplify().description, res3)

        let exp4 = x*(y/z)*(a/b)*c
        let res4 = "(x*y*a*c)/(z*b)"
        XCTAssertEqual(exp4.simplify().description, res4)
    }

    func testNumberCombining() {
        let one: Number = Number(1.0)
        let two: Number = Number(2.0)
        let three: Number = Number(3.0)

        let exp1 = one+two+three
        let res1 = "6.0"
        XCTAssertEqual(exp1.simplify().description, res1)

        let exp2 = three-two-one
        let res2 = "0.0"
        XCTAssertEqual(exp2.simplify().description, res2)

        let exp3 = three*two*one
        let res3 = "6.0"
        XCTAssertEqual(exp3.simplify().description, res3)

        let exp4 = Divide(three,two)
        let res4 = "1.5"
        XCTAssertEqual(exp4.simplify().description, res4)

        let exp5 = Power(two, three)
        let res5 = "8.0"
        XCTAssertEqual(exp5.simplify().description, res5)
    }

    func testEquality() {
        let one: Number = Number(1.0)
        let two: Number = Number(2.0)
        let three: Number = Number(3.0)
        let x = Variable("x")
        let y = Variable("y")
        let z = Variable("z")

        XCTAssertEqual(x, x)

        XCTAssertEqual(x+x, x+x)

        XCTAssertEqual(y-x, -1*x+y)

        XCTAssertEqual(z*y*x, x*y*z)

        XCTAssertEqual(one, one)

        XCTAssertEqual(one*three, three)
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

        XCTAssertEqual(x*x, Power(x, Number(2)))
        XCTAssertEqual(x*Power(x, Number(2)), Power(x, Number(3)))
        XCTAssertEqual(x*Power(x, y), Power(x, Number(1) + y))
        XCTAssertEqual(x*x*x, Power(x, Number(3)))
        
        XCTAssertEqual(x+x+x, 3*x)
    }

    static var allTests = [
        ("Leveling Tests", testLeveling),
        ("Rational Simplifying Tests", testRationalSimplifying),
        ("Number Combining", testNumberCombining),
        ("Equality", testEquality),
        ("Comparable", testComparable),
        ("Combine Like", testCombineLike),
    ]
}
