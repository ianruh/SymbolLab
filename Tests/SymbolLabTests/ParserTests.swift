import XCTest
@testable import SymbolLab

final class ParserTests: XCTestCase {
    
    var parser: Parser?
    
    var msg: String?
    
    override func setUp() {
        super.setUp()
        self.parser = Parser(debugMessageHandler: self.parseDebug)
    }
    
    func getMessage() -> String {
        if let str = self.msg {
            self.msg = nil
            return str
        }
        return ""
    }
    
    func parseDebug(_ msg: String) {
        self.msg = msg
    }
    
    func testGoodString(_ str: String, file: StaticString = #file, line: UInt = #line) {
        let nodeOpt: Node? = self.parser!.parse(cString: str)
        XCTAssertNotNil(nodeOpt, file: file, line: line)
        XCTAssertEqual(self.getMessage(), "", file: file, line: line)
        if let node = nodeOpt {
            XCTAssertEqual(str, node.description, file: file, line: line)
        }
    }
    
    func testBadString(_ str: String, file: StaticString = #file, line: UInt = #line) {
        let node: Node? = self.parser!.parse(cString: str)
        XCTAssertNil(node, file: file, line: line)
        XCTAssertNotEqual(self.getMessage(), "", file: file, line: line)
    }
    
//    private let operations: [Operation] = [Assign([P,P]), Decimal([P,P]), Negative([P,P]), Add([P,P]), Subtract([P,P]), Multiply([P,P]), Divide([P,P]), Power([P,P]), Factorial([P]), Parentheses([P]), Derivative([P,P]), Integral([P,P,P,P]), Sin([P])]
    
    func testAssign() {
        // Good
        testGoodString("1=1")
        testGoodString("1.2=3.4")
        testGoodString("1=12.3243")
        
        // Bad
        testBadString("=1")
        testBadString("1=")
        testBadString("1.3=")
        testBadString("=")
    }
    
    func testDecimal() {
        // Good
        testGoodString("1.23123")
        testGoodString("12312312.123213")
        testGoodString("0.123")
        
        // Bad
        testBadString(".1")
        testBadString("1.")
        testBadString("1.3.1.1.1")
        testBadString(".")
        testBadString("..")
    }
    
    func testNegative() {
        // Good
        testGoodString("2*(-1.23123)")
        testGoodString("-123213")
        testGoodString("-0.123")
        
        // Bad
        testBadString("1--")
        testBadString("--1")
        testBadString("-")
        testBadString("--")
    }

    
    func testAddition() {
        // Good
        testGoodString("1+2")
        testGoodString("1+1+1+1")
        testGoodString("1+1")
        
        // Bad
        testBadString("+1")
        testBadString("1+")
        testBadString("+")
    }
    
    func testSubtraction() {
        // Good
        testGoodString("1-2")
        testGoodString("1-1-1-1")
        testGoodString("1-1")
        
        // Bad
        testBadString("1-")
        testBadString("-")
    }
    
    func testMultiply() {
        // Good
        testGoodString("1*2")
        testGoodString("1*2*2*1-1")
        testGoodString("1-2*2")
        
        // Bad
        testBadString("1*")
        testBadString("*1")
        testBadString("*")
    }
    
    func testPower() {
        // Good
        testGoodString("1^2")
        testGoodString("1^2^2^1^1")
        testGoodString("1-2^2")
        
        // Bad
        testBadString("1^")
        testBadString("^1")
        testBadString("^")
    }
    
    func testPowerAssociativity() {
        let nodeOpt: Node? = self.parser!.parse(cString: "2^3^2")
        XCTAssertNotNil(nodeOpt)
        if let node = nodeOpt {
            XCTAssertEqual(node.symbol!.description, "512")
        }
    }
    
    func testFactorial() {
        // Good
        testGoodString("2!")
        testGoodString("(2*3)!")
        testGoodString("2*2!")
        
        // Bad
        testBadString("!")
        testBadString("!1")
        testBadString("1!1")
    }
    
    func testParentheses() {
        // Good
        testGoodString("(1*2)!")
        testGoodString("((((2*3))))")
        testGoodString("(1+2)*(1-3)")
        testGoodString("(1+(2+3+(4)*3*(2-3)))")
        
        // Bad
        testBadString("(")
        testBadString(")")
        testBadString("()")
        testBadString(")(")
        testBadString("(((1))")
        testBadString("(2,1)")
        testBadString("(2,)")
    }
    
    func testSingleArgumentFunction() {
        // Good
        testGoodString("sin(1*2)")
        testGoodString("sin((((2*3))))")
        testGoodString("sin(1+2)*sin(1-3)")
        testGoodString("(1+sin(2+3+sin(4)*3*(2-3)))")
        
        // Bad
        testBadString("sin(")
        testBadString(")sin")
        testBadString("sin()")
        testBadString(")(")
        testBadString("(sin((1))")
        testBadString("sin(2,1)")
        testBadString("sin(2,)")
    }
    
    func testMultipleArgumentFunction() {
        // Good
        testGoodString("int(x^2,x,2,8)")
        testGoodString("2+int((x^2)+2^9/1,x*2/3,1-3,7*3)")
        testGoodString("2+int(2+int((x^2)+2^9/1,x*2/3,1-3,7*3),x*2/3,1-3,7*3)+2+int((x^2)+2^9/1,x*2/3,1-3,7*3)")
        testGoodString("(1+sin(2+3+sin(4)*3*(2-3)))*sin(2+int((x^2)+2^9/1,x*2/3,1-3,7*3))")
        
        // Bad
        testBadString("int(x^2, x, 2,)")
        testBadString("int(x^2, x, 2)")
        testBadString("int()")
        testBadString("int(")
        testBadString(")(")
        testBadString("int(, x, 2, 8)")
        testBadString("int(x^2, x, 2, 8, 1)")
        testBadString("int(x^2, x, 2, 8),")
        testBadString("()int")
    }
    
    func testSpecificCases() {
        testGoodString("asech(d(64,x)-z!)")
        testGoodString("acosh(log((8.8+((445!)!)!)^-357))")
        testGoodString("acosh(int(83-(38!-866/8)^334.30+1.787,(-85+(545*26)^-2/(2+w)^(0+547))*(d-13+51+y),3.50,886))")
        testGoodString("(133-(w!-b)^(73-a))*446.623/(4.577-541)*-350")
    }

    static var allTests = [
        ("Addition Tests", testAddition),
        ("Subtraction Tests", testSubtraction),
        ("Assignment Tests", testAssign),
        ("Decimal Tests", testDecimal),
        ("Negative Tests", testNegative),
        ("Multiply Tests", testMultiply),
        ("Factorial Tests", testFactorial),
        ("Parentheses Tests", testParentheses),
        ("Single Argument Function Tests", testSingleArgumentFunction),
        ("Multiple Argument Function Tests", testMultipleArgumentFunction),
        ("Power Tests", testPower),
        ("Power Associativity Tests", testPowerAssociativity),
        ("Specific test cases", testSpecificCases),
    ]
}
