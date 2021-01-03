//
//  File.swift
//  
//
//  Created by Ian Ruh on 5/14/20.
//
import Foundation
import ArgumentParser

// dampedMassSpring()
//rocket()
// minimizeExample()

struct Examples: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "Examples for the SymbolLab library.",
        subcommands: [DampedSpring.self, Minimize.self, Rocket.self])
}

extension Examples {
    struct DampedSpring: ParsableCommand {
        static var configuration = CommandConfiguration(commandName: "spring", abstract: "Run the damped spring example. Requires python and matplotlib to function.")

        mutating func run() {
            dampedMassSpring()
        }
    }

    struct Minimize: ParsableCommand {
        static var configuration = CommandConfiguration(commandName: "minimize", abstract: "Run the damped spring example.")

        mutating func run() {
            minimizeExample()
        }
    }

    struct Rocket: ParsableCommand {
        static var configuration = CommandConfiguration(commandName: "rocket", abstract: "Run the rocket equation example.")

        mutating func run() {
            // rocket()
            print("This example is currently broken.")
        }
    }
}

Examples.main()