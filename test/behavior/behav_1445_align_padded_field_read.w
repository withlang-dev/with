//! expect-stdout: a=5 b=1111111111111 c=2222222222222 size=32
//! expect-stdout: 1111111111111 2222222222222
//! expect-stdout: A { a: 5, b: 1111111111111, c: 2222222222222 }
//! expect-stdout: true

// #1445: reading a field after an `@[align(N)]` padding member indexes the
// LLVM body by the field's LLVM position, not its source index. The direct
// read printed <unsupported> (the padding array's type) and a later field's
// value was read from the wrong slot. Direct read, read through a borrow,
// Debug formatting and equality.
type A {
    a: i8,
    @[align(16)]
    b: i64,
    c: i64,
}

fn through(v: &A) -> i64: v.b

fn main:
    let v = A { a: 5, b: 1111111111111, c: 2222222222222 }
    let b = v.b
    print(f"a={v.a} b={b} c={v.c} size={size_of[A]()}")
    print(f"{through(&v)} {v.c}")
    print(f"{v:?}")
    let w = A { a: 5, b: 1111111111111, c: 2222222222222 }
    print(f"{v == w}")
