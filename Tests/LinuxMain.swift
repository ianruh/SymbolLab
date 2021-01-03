import XCTest

import SymbolLabTests
import SwiftBackendTests

var tests = [XCTestCaseEntry]()
tests += SymbolLabTests.allTests()
tests += SwiftBackendTests.allTests()
XCTMain(tests)
