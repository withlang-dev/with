//! expect-stdout: 5 7
//! expect-stdout: 3
//! expect-stdout: 9 1
//! expect-stdout: 4 4

// #1440: a generic type declared after the declaration that uses it resolves
// like a non-generic one does; declaration order does not matter. A struct
// field, an enum payload, an alias, a distinct type's inner type, and a
// generic that uses a later generic.
type Holder { g: Gen[i32], w: Wrap[i64] }

enum Choice:
    H(g: Gen[Inner])
    N

type Pairs = Gen[Wrap[i32]]

type Outer[T] { inner: Wrap[T], count: i32 }

fn main:
    let h = Holder { g: Gen { t: 5 }, w: Wrap { v: 7 } }
    print(f"{h.g.t} {h.w.v}")
    let c = Choice.H(Gen { t: Inner { v: 3 } })
    match c:
        .H(g) => print(f"{g.t.v}")
        .N => print("n")
    let p: Pairs = Gen { t: Wrap { v: 9 } }
    let o: Outer[i32] = Outer { inner: Wrap { v: 1 }, count: 0 }
    print(f"{p.t.v} {o.inner.v}")
    let d = Many { v: 4 }
    print(f"{d.v} {d.v}")

type Inner { v: i32 }
type Gen[T] { t: T }
type Wrap[T] { v: T }
type Many { v: i32 }
