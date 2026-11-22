//! expect-stdout: 42 42 7
// A global initializer that creates a closure: passed to a function
// (`doubled`), stored as the global's value and called later (`adder`), and
// capturing another global (`scaled`). Its bodies are lowered with the
// module, as a function's closures are; lowered in a backend they reached
// no module and codegen stopped ("anonymous expression lacks retained MIR").
fn apply(g: fn(i64) -> i64, x: i64) -> i64: g(x)

let doubled = apply((v: i64) => v * 2, 21)
let adder: fn(i64) -> i64 = (v: i64) => v + 1
let base: i64 = 3
let scaled = apply((v: i64) => v + base, 4)

fn main:
    print(f"{doubled} {adder(41)} {scaled}")
