//! expect-stdout: 1.5
//! expect-stdout: 3.14159
//! expect-stdout: 6.28318
//! expect-stdout: -2.5
//! expect-stdout: true
//! expect-stdout: pi=3.14159

// #1668 / §9.1b: a float literal is a comptime value — in a `const`, under
// arithmetic, negation, comparison and f-string interpolation — and the
// folded value is the value the same expression has at run time.
const HALF: f64 = 1.5
const PI = 3.14159
const TAU: f64 = PI * 2.0
const NEG: f64 = -2.5
const BIG: bool = TAU > PI
const LABEL: str = f"pi={PI}"
fn main:
    print(HALF)
    print(PI)
    print(TAU)
    print(NEG)
    print(BIG)
    print(LABEL)
