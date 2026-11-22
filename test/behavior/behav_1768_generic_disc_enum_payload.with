//! expect-stdout: 42
//! expect-stdout: 40
//! expect-stdout: 5
//! expect-stdout: 3
//! expect-stdout: 201
//! expect-stdout: x

// #1768 (§4.4a): a generic discriminant enum with a payload variant. The
// generic-enum payload and substitution walkers read only the plain enum's
// extras layout, so `E[i64].B`'s payload reached MIR unresolved ("use rvalue
// does not resolve to a concrete MIR type") and `print(v)` could not infer T.

enum E[T]: i32:
    A = 3
    B(T) = 5

fn main:
    let b: E[i64] = E.B(40)
    match b:
        E.B(v) =>
            let w: i64 = v + 2
            print(w)
        _ => print("other")
    let c: E[i64] = E.B(40)
    match c:
        E.B(v) => print(v)
        _ => print("other")
    print(E.B(40) as i32)
    let a: E[i64] = E.A
    print(a as i32)
    let n: N[str] = N.Two("x")
    print(n as i32)
    match n:
        N.Two(s) => print(s)
        _ => print("other")

// A generic discriminant enum in a narrower repr: the discriminant read is
// typed by the base enum's repr (u8), not the generic instance.
enum N[T]: u8:
    One = 200
    Two(T) = 201
