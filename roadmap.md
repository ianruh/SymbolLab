# SymbolLab Road Map

- [ ] Change name (possibly ACausal Swift)

- [ ] Units (probably using or wrapping the stdlib unit system)

- [ ] Operators on nodes (*/+-)

- [ ] ODEs

- [ ] Standardize excpetions vs returning optionals

- [ ] Commenting/documentation

- [ ] Varying parameters and getting ranges.

- [ ] Graphing

- [ ] SymEngine and SymPy backend

- [ ] Real way of reconstructing node from SymEngine object

- [ ] Componetized construction of systems

  - Make `Component` a protocol. Maybe:

    ```swift
    /**
    Describes the connection between two components
    */
    protocol Pin {
        var variables: [Variable] {get}
    }
    
    /**
    Describes two components
    */
    protocol Component {
        var equations: [Node] {get}
        var inputs: [Pin] {get}
        var  outputs: [Pin] {get}
        
        init(input: [Pin] = [], output: [Pin] = [])
    }
    ```

    