//
//  File.swift
//  
//
//  Created by Ian Ruh on 5/14/20.
//

import Foundation
import SymbolLab


//Parser.parseCString("1+211*132^s/(yzt-3*2)-3.1415")
let parser = Parser()
//let nodeOpt: Node? = parser.parseCString("x-2*3/3-1")
let nodeOpt: Node? = parser.parse(cString: "d(sin(x),x)")

if let node = nodeOpt {
    print(node.symbol)
} else {
    print("Node is nil")
}

//let str =  "1+2-2(3*6)"
