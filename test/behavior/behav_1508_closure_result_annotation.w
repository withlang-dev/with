//! expect-stdout: 2!
//! expect-stdout: 2147483648 -5
//! expect-stdout: 2147483648
//! expect-stdout: <14>
//! expect-stdout: 7
//! expect-stdout: ok

// D71 / §12 (#1508): a closure may state its result type as a function does,
// `(x: i32) -> str => f"{x}"`; the annotation is checked like a declared
// return type and is never dropped. The parser read the `-> T` and discarded
// it, so the closure's result was its body's type: `g` below returned an i32
// and `g(i32_max) + 1` overflowed, and `apply` bound U to i32.

fn apply[T, U](x: T, f: fn(T) -> U) -> U: f(x)

fn main:
    let f = (x: i32) -> str => f"{x}"
    print(f(2) ++ "!")
    // The body's i32 widens into the declared i64, as it does in
    // `fn g(x: i32) -> i64: x`.
    let g = (x: i32) -> i64 => x
    print(f"{g(2147483647) + 1} {g(-5)}")
    // A generic result binds from the annotation.
    print(apply(2147483647, (x: i32) -> i64 => x) + 1)
    // A block body, and a zero-parameter closure.
    let tag = (x: i32) -> str =>
        let doubled = x * 2
        f"<{doubled}>"
    print(tag(7))
    let seven = () -> i64 => 7
    print(seven())
    let owned = move (x: i32) -> bool => x > 0
    assert(owned(1))
    print("ok")
