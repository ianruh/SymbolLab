//
//  File.swift
//  
//
//  Created by Ian Ruh on 5/16/20.
//
// Extensions of types not defined in this repo

import Foundation

extension String {
    var isInteger: Bool {
        guard self.count > 0 else { return false }
        let nums: Set<Character> = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
        return Set(self).isSubset(of: nums)
    }
    
    var isDouble: Bool {
        guard self.count > 0 else { return false }
        let parts = self.split(separator: ".")
        if(parts.count == 2) {
            return String(parts[0]).isInteger && String(parts[1]).isInteger
        } else if(parts.count == 1) {
            return String(parts[0]).isInteger
        }
        return false
    }
    
    var isNumber: Bool {
        return self.isInteger || self.isDouble
    }

    var isAlphabetic: Bool {
        guard self.count > 0 else { return false }
        let nums: Set<Character> = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"]
        return Set(self).isSubset(of: nums)
    }
    
    public func cleanWhiteSpace() -> String {
        var str = ""
        let whitespace: Set<Character> = [" ", "\t", "\n"]
        for c in self {
            if(!whitespace.contains(c)) {
                str += String(c)
            }
        }
        return str
    }
    
    var hasValidParetheses: Bool {
        var level = 0
        for c in self {
            if(c == "(") {
                level += 1
            } else if(c == ")") {
                level -= 1
            }
            // handle ))((
            if(level < 0) {
                return false
            }
        }
        return level == 0
    }
}


extension Int {
    public static func random(withDigits digits: Int) -> Int {
        var str = ""
        for _ in 0..<digits {
            str += String(Int.random(in: 0..<9))
        }
        return Int(str)!
    }
    
    public static func random(withMaxDigits maxDigits: Int) -> Int {
        return Int.random(withDigits: Int.random(in: 1...maxDigits))
    }
    
}

extension Collection where Element: CustomStringConvertible {
    public func join(separator: String) -> String {
        var str = ""
        for e in self.dropLast() {
            str += "\(e)\(separator)"
        }
        str += "\(self[self.endIndex])"
        return str
    }
}
