//
// Created by Ian Ruh on 8/29/20.
//

//----------------------- Protocol Definitions -----------------------

public protocol Integrator {
    /// Integrate the given node over the given range.
    ///
    /// The implementation is responsible for checking the validity of the given node.
    ///
    /// - Parameters:
    ///   - equation: The node to integrate.
    ///   - from: Lower bound of the integral.
    ///   - to: Upper bound of the integral.
    /// - Returns: The numeric approximation to the integral.
    /// - Throws: If something bad happens (e.g. assignment in the node)
    func integrate(_ equation: (Double) throws -> Double, from: Double, to: Double) throws -> Double
}
extension Integrator {
    /// Integrate the given node over the given range.
    ///
    /// Just wraps the `func integrate(_ equation: Node, from: Double, to: Double) throws -> Double` function.
    ///
    /// - Parameters:
    ///   - equation: The node to integrate.
    ///   - range: The range to integrate over.
    /// - Returns: The numerical approximation of the integral.
    /// - Throws: If something bad happens.
    func integrate(_ equation: (Double) throws -> Double, over range: ClosedRange<Double>) throws -> Double {
        return try self.integrate(equation, from: range.lowerBound, to: range.upperBound)
    }
}

//----------------------- Utilities -----------------------

/// Get the points in the range by the given step. Gaurenteed to have start and end points included, but the last step may not be of size h.
///
/// - Parameters:
///   - start: Start of sequence.
///   - end: End of seuqnce.
///   - step: Value to step by.
/// - Returns: Array of points.
internal func inclusiveStride(from start: Double, through end: Double, by step: Double) -> [Double] {
    var points: [Double] = [start]
    while(points.last! < end) {
        points.append(points.last! + step)
    }
    points.append(end)
    return points
}

//----------------------- Implementations -----------------------

/// Forward Euler integrator.
///
/// [Reference](https://en.wikipedia.org/wiki/Euler_method)
public struct ForwardEuler: Integrator {

    /// The step size used in integration
    public var h: Double

    /// Basic initializer
    public init(h: Double) {
        self.h = h
    }

    public func integrate(_ equation: (Double) throws -> Double, from: Double, to: Double) throws -> Double {
        let points = inclusiveStride(from: from, through: to, by: self.h)
        var runningSum: Double = 0
        for i in 0..<points.count-1 {
            runningSum += try equation(points[i])*(points[i+1] - points[i])
        }
        return runningSum
    }
}

/// Midpoint integrator.
///
/// [Reference](https://en.wikipedia.org/wiki/Midpoint_method)
public struct Midpoint: Integrator {

    /// The step size used in integration
    public var h: Double

    /// Basic initializer
    public init(h: Double) {
        self.h = h
    }

    public func integrate(_ equation: (Double) throws -> Double, from: Double, to: Double) throws -> Double {
        let points = inclusiveStride(from: from, through: to, by: self.h)
        let values = try points.map({try equation($0)})

        var runningSum: Double = 0
        for i in 0..<points.count-1 {
            runningSum += (points[i+1] - points[i])*(values[i] + values[i+1])/2
        }
        return runningSum
    }
}


