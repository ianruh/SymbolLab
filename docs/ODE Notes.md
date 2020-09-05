# ODE Notes

System:

```swift
let x = Variable("x", initialValue: 1)
let t = Variable("t")
let system: System = [
    Derivative(x, t) ~ -0.2 * x
]
```

**Solution Steps**

1. The constraint check should come back one short (same as if we were varying any variable)

2. We identify the ODE(s), check that all of the ODEs are with repsect to the same variable, check that the range for that variable is given.

3. Check that the independent variable of the ODE is a simple independent variable. (Maybe have a simple der(var, var) function to make the derivative)

4. Replace the deirvative with a new variable and add the initial x constraint:

   ```swift
   system = [
       newV ~ -0.2 * x,
       x ~ 1
   ]
   ```

5. Solve the system for the new variable, which equals $f(x,t)$ from here on.
6. Find the next value of x: $$x_{n+1} = x_n + h * f(x,t)$$

