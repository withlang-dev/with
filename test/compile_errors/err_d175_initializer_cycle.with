//! expect-error: the initializers of globals read one another, so none can run first: the initializer of `a`, which reads `b`, which reads `a` (§9.1c, D175)
// D175: a global's initializer runs after every global it reads; two that
// read each other have no first.
let a = b + 1
let b = a + 1

fn main:
    print(f"{a}")
