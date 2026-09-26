//! expect-stdout: 2
//! expect-stdout: nested 6
//! expect-stdout: nested Y
//! expect-stdout: B
//! expect-stdout: nested 8

// #1507 / #1518: a qualified pattern `G.V(t)` names the enum; the subject's
// instance `G[i64]` types the payload. The qualifier's bare `G` typed `t`
// as `T` (so `print(t)` could not infer a type parameter) and left the
// binding of a nested `G.A(.X(t))` undeclared.

enum G[T]:
    V(t: T)
    E

enum H[T]:
    X(t: T)
    Y

enum Outer[T]:
    A(h: H[T])
    B(n: i64)

fn nested(g: Outer[i64]) -> str:
    match g:
        Outer.A(.X(t)) => f"nested {t}"
        Outer.A(.Y) => "nested Y".clone()
        Outer.B(_) => "B".clone()

fn nested_qualified(g: Outer[i64]) -> str:
    match g:
        Outer.A(H.X(t)) => f"nested {t}"
        Outer.A(H.Y) => "nested Y".clone()
        Outer.B(_) => "B".clone()

fn main:
    let f: G[i64] = G.V(2)
    match f:
        G.V(t) => print(t)
        G.E => print("E")
    print(nested(Outer.A(H.X(6))))
    print(nested(Outer.A(H.Y)))
    print(nested(Outer.B(1)))
    print(nested_qualified(Outer.A(H.X(8))))
