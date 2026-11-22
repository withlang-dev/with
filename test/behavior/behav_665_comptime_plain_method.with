//! expect-stdout: 8 5

// #665 (§17.1, D104): a `comptime fn` may call a plain method, as it may
// call a plain function: it is judged by what it reaches. `p.twice()` was
// refused ("comptime can only call comptime functions") where the free
// `twice(p)` was accepted.
type P { n: i32 }

impl P:
    fn twice() -> i32: self.n * 2
    fn plus(k: i32) -> P: P { n: self.n + k }

comptime fn go() -> i32:
    let p = P { n: 4 }
    p.twice()

comptime fn chained() -> i32: P { n: 2 }.plus(3).n

const N = go()
const M = chained()

fn main: print(f"{N} {M}")
