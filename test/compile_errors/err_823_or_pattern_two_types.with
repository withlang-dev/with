//! expect-check-fail: `x` is `i32` in the first alternative and `str` in this one; a name bound by an or-pattern has one type (§9.7)

// #823: one name, one type.
enum E:
    A(n: i32)
    B(s: str)

fn h(e: E) -> i32:
    match e:
        .A(x) | .B(x) => 1

fn main: print(h(.A(1)))
