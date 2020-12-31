
// public extension System {
//     /// Solve the system over a range of values. Currently, only support a range for one value, but that is mostly just
//     /// because the graphing library only has 2d support at the moment.
//     ///
//     ///
//     /// - Parameters:
//     ///   - overRange: A dictionary with the variable to vary associated with the desired range. e.g. `["x": 0.0..<10.0]`
//     ///   - initialGuess: A set of initial guesses for the other variables at the beginning of the range.
//     ///   - threshold: Same as solve without range.
//     ///   - maxIterations: Same as solve without range.
//     /// - Returns: The array of values, the array of errors, and the array of iterations.
//     /// - Throws: For many reasons. Look at the return message.
//     public func solve<Engine: SymbolicMathEngine>(overRange ranges: [Node: Range<Double>],
//                       withStride: Double,
//                       initialGuess: [Node: Double] = [:],
//                       threshold: Double = 0.0001,
//                       maxIterations: Int = 1000,
//                       using backend: Engine.Type) throws -> (values: [[Node: Double]],
//                                                             error: [Double],
//                                                             iterations: [Int]) {

//         // Check we only have one variable
//         guard ranges.count == 1 else {
//             throw SymbolLabError.misc("Currently solve only can evaluate at one set of points.")
//         }
//         let (variable, range) = ranges.first!
//         // Make our array
//         let points: [Double] = Array(stride(from: range.lowerBound, to: range.upperBound, by: withStride))
//         return try self.solve(at: points, initialGuess: initialGuess, threshold: threshold, maxIterations: maxIterations, using: backend)
//     }

//     /// Solve the system over a range of values. Currently, only support a range for one value, but that is mostly just
//     /// because the graphing library only has 2d support at the moment.
//     ///
//     ///
//     /// - Parameters:
//     ///   - overRange: A dictionary with the variable to vary associated with the desired range. e.g. `["x": 0.0..<10.0]`
//     ///   - initialGuess: A set of initial guesses for the other variables at the beginning of the range.
//     ///   - threshold: Same as solve without range.
//     ///   - maxIterations: Same as solve without range.
//     /// - Returns: The array of values, the array of errors, and the array of iterations.
//     /// - Throws: For many reasons. Look at the return message.
//     public func solve<Engine: SymbolicMathEngine>(overRange ranges: [Node: ClosedRange<Double>],
//                       withStride: Double,
//                       initialGuess: [Node: Double] = [:],
//                       threshold: Double = 0.0001,
//                       maxIterations: Int = 1000,
//                       using backend: Engine.Type) throws -> (values: [[Node: Double]],
//                                                             error: [Double],
//                                                             iterations: [Int]) {

//         // Check we only have one variable
//         guard ranges.count == 1 else {
//             throw SymbolLabError.misc("Currently solve only can evaluate at one set of points.")
//         }
//         let (variable, range) = ranges.first!
//         // Make our array
//         let points: [Double] = Array(stride(from: range.lowerBound, through: range.upperBound, by: withStride))
//         return try self.solve(at: points, initialGuess: initialGuess, threshold: threshold, maxIterations: maxIterations, using: backend)
//     }
// }