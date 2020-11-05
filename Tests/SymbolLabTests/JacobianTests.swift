//
// Created by Ian Ruh on 11/4/20.
//

import XCTest
import SwiftBackend
@testable import SymbolLab

final class JacobianTests: XCTestCase {

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
        assertNodesEqual(jacobian.elements[0][0], result, ["2.0*1"])
    }


    static var allTests = [
        ("Jacobian 1x1 Test", testOneByOne),
    ]
}
