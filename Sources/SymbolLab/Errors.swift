//
//  File.swift
//  
//
//  Created by Ian Ruh on 8/16/20.
//

/**
Errors that can be thrown by SymbolLab
*/
public enum SymbolLabError: Error {
    case noValue(forVariable: String)
    case notApplicable(message: String)
    case noVariable(forValue: String)
    case misc(_ message: String)
}
