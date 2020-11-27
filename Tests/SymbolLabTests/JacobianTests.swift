//
// Created by Ian Ruh on 11/4/20.
//

import XCTest
import SwiftBackend
@testable import SymbolLab

final class JacobianTests: XCTestCase {

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

    func testOneByOne() {
        let x = Variable("x")
        let system: System = [
            2*x + 1
        ]
        guard let jacobian = Jacobian<SwiftBackend>(system: system) else {
            XCTFail("Couldn't construct jacobian for system \(system)")
            return
        }

        let result = Number(2)
        assertNodesEqual(jacobian.elements[0][0], result)
    }


    static var allTests = [
        ("Jacobian 1x1 Test", testOneByOne),
    ]
}
