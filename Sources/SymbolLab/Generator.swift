//
//  File.swift
//  
//
//  Created by Ian Ruh on 5/17/20.
//

public struct GeneratorOptions {
    // General Options
    public var maxDepth: Int
    public var probabilityBasic: Double
    
    // Numbers
    public struct Numbers {
        public var maxWholeDigits: Int
        public var maxDecimalDigits: Int
        
        public init(maxWholeDigits: Int = 3,
                    maxDecimalDigits: Int = 3) {
            self.maxWholeDigits = maxWholeDigits
            self.maxDecimalDigits = maxDecimalDigits
        }
    }
    public var numbers = Numbers()
    
    // Variables
    public struct Variables {
        public var names: [String]
        
        public init(names: [String] = ["a", "b", "c", "d", "w", "x", "y", "z"]) {
            self.names = names
        }
    }
    public var variables = Variables()
    
    // Operations
    public struct Operations {
        public var list: [Operation]
        public var maxFunctionDepth: Int
        
        // Assignment
        public struct Assignment {
            public var allowNoneTopLevel: Bool
            public var maxChain: Int
            
            public init(allowNoneTopLevel: Bool = false,
                        maxChain: Int = 2) {
                self.allowNoneTopLevel = allowNoneTopLevel
                self.maxChain = maxChain
            }
        }
        public var assignments = Assignment()

        // Fraction
        public struct Fraction {
            public var maxDepth: Int
            
            public init(maxDepth: Int = 1) {
                self.maxDepth = maxDepth
            }
        }
        public var fractions = Fraction()
        
        // Exponent
        public struct Exponent {
            public var maxDepth: Int
            
            public init(maxDepth: Int = 1) {
                self.maxDepth = maxDepth
            }
        }
        public var exponents = Exponent()
        
        public init(list: [Operation] = Parser.allOperations,
                    maxFunctionDepth: Int = 2,
                    assignments: GeneratorOptions.Operations.Assignment = Assignment(),
                    fractions: GeneratorOptions.Operations.Fraction = Fraction(),
                    exponents: GeneratorOptions.Operations.Exponent = Exponent()) {
            self.list = list
            self.maxFunctionDepth = maxFunctionDepth
            self.assignments = assignments
            self.fractions = fractions
            self.exponents = exponents
        }
    }
    public var operations = Operations()
    
    public init(maxDepth: Int = 4,
                  probabilityBasic: Double = 0.15,
                  numbers: GeneratorOptions.Numbers = Numbers(),
                  variables: GeneratorOptions.Variables = Variables(),
                  operations: GeneratorOptions.Operations = Operations()) {
        self.maxDepth = maxDepth
        self.probabilityBasic = probabilityBasic
        self.numbers = numbers
        self.variables = variables
        self.operations = operations
    }
    
    /**
     Select  a random operation from the list of valid operations, possibly excluding a given set.
     */
    public func randomOperation(excluding: [Operation] = []) -> Operation {
        var selectedOperations: [Operation] = self.operations.list
        for exOp in excluding {
            selectedOperations.removeAll(where: { (op: Operation) -> Bool in
                return exOp.identifier == op.identifier &&
                    exOp.associativity == op.associativity &&
                    exOp.precedence == op.precedence &&
                    exOp.type == op.type
            })
        }
        // Assume we have at least one operation
        return selectedOperations.randomElement()!
    }
    
    /**
     Remove the given operation from the list of operations.
     */
    public mutating func remove(operation: Operation) {
        self.operations.list.removeAll(where: { (currOp: Operation) -> Bool in
            return operation.identifier == currOp.identifier &&
                operation.associativity == currOp.associativity &&
                operation.precedence == currOp.precedence &&
                operation.type == currOp.type
        })
    }
    
    /**
     Remove the all functions.
     */
    public mutating func removeFunctions() {
        self.operations.list.removeAll(where: { (op: Operation) -> Bool in
            return (op as? Function) != nil
        })
    }
}

// Only used for generating to track the depth of certain operations
public struct Depths {
    var fractionDepth: Int
    var exponentDepth: Int
    var assignmentDepth: Int
    var functionDepth: Int
    var depth: Int

    
    public init() {
        self.fractionDepth = 0
        self.exponentDepth = 0
        self.assignmentDepth = 0
        self.functionDepth = 0
        self.depth = 0
    }
}

public struct GeneratorUtilities {
    /**
     Update the set  of possible operations based on the current depths.
     */
    public static func updateOperations(_ options: inout GeneratorOptions, withDepths depths: Depths) {
        // Check fraction depth
        if(depths.fractionDepth >= options.operations.fractions.maxDepth) {
            options.remove(operation: Divide([P,P]))
        }
        
        // Check the exponent depth
        if(depths.exponentDepth >= options.operations.exponents.maxDepth) {
            options.remove(operation: Power([P,P]))
        }
        
        // Check assignment depth
        if(!options.operations.assignments.allowNoneTopLevel && (depths.depth > depths.assignmentDepth || depths.assignmentDepth >= options.operations.assignments.maxChain)) {
            options.remove(operation: Assign([P,P]))
        }
        
        // Check function depth
        if(depths.functionDepth >= options.operations.maxFunctionDepth) {
            options.removeFunctions()
        }
    }
    
    /**
     Create a random new node.
     */
    public static func randomNode(_ options: inout GeneratorOptions, withDepths depths: Depths = Depths()) -> Node {
        if(Double.random(in: 0...1) < options.probabilityBasic || depths.depth >= options.maxDepth-1) {
            // The new node is a variable or a number (basic values)
            if(Bool.random()) {
                // Variable
                return Variable(options.variables.names.randomElement()!)
            } else {
                // Number
                return Number(1).generate(withOptions: options, depths: depths)
            }
        } else {
            // The new node is another operations
            GeneratorUtilities.updateOperations(&options, withDepths: depths)
            return options.randomOperation().generate(withOptions: options, depths: depths)
        }
    }
}
