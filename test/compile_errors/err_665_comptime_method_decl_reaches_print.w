//! expect-check-fail: is not comptime-callable: it reaches print

// #665 (§17.1, D104): a `comptime fn` method is checked at its declaration,
// as a `comptime fn` is: its body may call only what runs at compile time.
type P { n: i32 }

impl P:
    comptime fn noisy() -> i32:
        print("hi")
        self.n

fn main: print(P { n: 1 }.n)
