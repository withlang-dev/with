//! expect-check-fail: 'P.shout' is not comptime-callable: it reaches P.shout -> print -> with_println_str (an extern)

// #665 (§17.1, D104): a plain method called from a `comptime fn` is judged
// by what it reaches, and the refusal names the chain to the operation that
// does not run at compile time, as it does for a plain function.
type P { n: i32 }

impl P:
    fn shout() -> i32:
        print("hi")
        self.n

comptime fn go() -> i32:
    let p = P { n: 4 }
    p.shout()

const N = go()

fn main: print(N)
