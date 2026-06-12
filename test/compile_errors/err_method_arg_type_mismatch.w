//! expect-check-fail: wrong argument type

// #567: plain-receiver method arguments must be type-checked. A str
// where i32 is declared previously sailed through sema entirely.

type Acc { n: i32 }

fn Acc.take(self: &Self, x: i32) -> i32:
    self.n + x

fn main:
    let a = Acc { n: 1 }
    let r = a.take("oops")
    print(f"{r}")
