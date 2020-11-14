import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(SymbolLabTests.allTests),
        // testCase(ParserTests.allTests),
        testCase(JacobianTests.allTests)
    ]
}
#endif
