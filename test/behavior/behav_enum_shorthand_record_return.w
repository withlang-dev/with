//! expect-stdout: ok

enum D {  | X }
    | Y

type S {
    d: D,
}

fn make -> S:
    S { d: .X }

fn main:
    let s = make()
    assert(s.d == .X)
    print("ok")
