//
//  File.swift
//  
//
//  Created by Ian Ruh on 8/16/20.
//

/**
Errors that can be thrown by SymEngine
*/
public enum SymbolLabError: Error {
    case noValue(forVariable: String)
    case notApplicable(message: String)
}
