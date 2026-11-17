//! expect-stdout: 12

// #665 (§17.1, D104): `comptime fn` declares that a function runs at
// compile time; a method takes the keyword where a function does. It was a
// parse error inside an `impl` ("expected a member of this `impl`").
type P { n: i32 }

impl P:
    comptime fn triple() -> i32: self.n * 3

comptime fn go() -> i32: P { n: 4 }.triple()

const N = go()

fn main: print(N)
