# SymbolLab

This is an experimental numerical modeling library that should likely not be used for anything important. It incorporates a custom symbolic math library (there are several better ones that could have been used, e.g. SymEngine, but this project is significantly for learning purposes.), an acausal modeling system, and first-order ODE solving.

## Getting Started

The easiest way to get the code running is by building the docker file contained in the repository:

```
$ docker build -f docker/Dockerfile -t symbollab:base .
$ docker build -f docker/Dockerfile.extended -t symbollab:examples .
$ docker run --rm -it symbollab:examples /bin/bash
root@------------:/SymbolLab# swift run examples spring --no-gui
```

You should be met by some ascii art of the position and velocity graphs of a damped harmonic oscillator. If you omit the `--no-gui` flag, then the results are plotted with matplotlib (shown below), but this will not work if it is running in a docker container.

## Example Walkthrough

**Damped Oscillator**

Next, we can start defining our system. First, we declare all of the variables we are going to need (I've declared the constants here as well using the `Number` type, but they could be put directly into the system as `-0.5` is further below).

```swift
let m: Number = 1.0          // Mass
let k: Number = 4.0          // Spring constant
let b: Number = 0.4          // Damping parameter
let ff = Variable("ff")                 // Damping force
let fs = Variable("fs")                 // Spring force
let x = Variable("x", initialValue: 2)  // Mass position
let v = Variable("v", initialValue: 0)  // Mass velocity
let t = Variable("t")                   // Time
```

The `Number` type is for numbers (backed by doubles, not arbitrary precision).

The `Variable` type declares each variable we are going to use in the system. For the `x` and `v` variables, we provide an initial values along with the name because they are the two depedent variables in the system below:

```swift
let system: System = [
    ff ≈ -1.0 * b*v,                                        // Damping force
    fs ≈ -0.5 * (k*x),                                      // Spring force
    Derivative(of: v, wrt: t) ≈ (fs + ff)/m,
    Derivative(of: x, wrt: t) ≈ v
]
```

[^1]: This definition of the system is more verbose than I would normally write it. However, the Swift compiler has a difficult time determining types when the expressions for the damping force and spring force are included directly in the ODE. The workaround for when it complains it can't determine types is just to break apart the expression as was done for the two forces above.

Here, we construct a simple system for a damped oscilator. Most of the operators (`+,-,*,/,**`) for basic math should 'Just Work' with all of the types in SymbolLab. In this system, we constructed an ODE using a `Derivative` object, but one could also construct an expression using an deirvative that can be immediately calculated (e.g. `Derivative(of: x**2, wrt: x)`, which would evaluate to `2*x`).

We also have to define the range over which we want to solve the ODE (look at the Notes section for some details about this):

```swift
var tVals = Array(stride(from: 0.0, through: 20.0, by: 0.01)) // Time values to use
```

Now, we can solve out system and plot it. For this example, and for the examples in `Sources/Examples/`, we use [SwiftPlot](https://github.com/KarthikRIyer/swiftplot) for plotting, though any other library should work.

```swift
do {
    // Solve the system and extract the position and velocity
    let (values, errors, iterations) = try system.solve(at: ["t": tVals], using: SymEngineBackend.self)
    var xVals = values.map({$0["x"]!})
    var vVals = values.map({$0["v"]!})

    //... Plotting Code ...//
    // Look at the examples for details
} catch {
    print(error)
}
```

![Damped Mass on a Spring](./docs/dampedspring.svg)

## Notes

**ODE Solving**

The current method for solving ODEs is just forward euler, so it won't be very stable or accurate comparatively. I'm planning on implementing a solver framework to support general implicit and explicit methods.

**Supported Platforms**

MacOS and Linux. No reason it shouldn't work on windows that I know of, but I haven't tested it.

## FAQ

**Should this be used for anything remotely important?**

Not if you value your job.

## ToDo

- Generalized ODE solving framework to support explicit and implicit methods.

- Actual constraint checking, and using this to solve independent subsystems individually rather than solve everything all at once.

- Componetized system construction. i.e.

  ```swift
  public protocol Component {}
  
  public struct Pump: Component {
      public var constraints: System {
          m_dot_in ≈ m_dot_out,
          h_dot_in ≈ h_dot_out,
          self.pressureRatio ≈ pressure_out / pressure_in,
          ...
      }
      
      public init(pr pressureRatio: Double) {}
  }
  
  
  
  let wholeSystem = Pump(pr: 2) -> Pump(pr: 5)
  ```

  This would make modeling of more complex physical systems much easier.

- Add units to variables and numbers to check the dimensionality of equations.

## Plan of Attack

*In order*

- [x] Symoblic math operations (simplification, cannonical forms, fix the derivative of variables) based on [this](http://www.math.wpi.edu/IQP/BVCalcHist/calc5.html#_Toc407004380).
- [x] Check the handling of implicit derivatives. I don't remeber what this was.
- [x] Derivatives as solvable values.
- [ ] Implicit integration framework (euler, RK maybe)
- [ ] Derivatives of the solution to ODE at furture time T.
- [ ] Optimization over systems of non-linear ODEs.

*Would be nice*
- [ ] Constraint graph. Particularly if we have a large system with a couple ODEs, it would be better to not do the implict integration steps with the entire systems, but instead just the necessary parts.
