//! expect-stdout: X 3
//! expect-stdout: B 7
//! expect-stdout: X 3

// #2549 (D111): an enum whose payloads are all values has no identity, so
// it is a value as a struct of values is (D120): a match on a bare local
// observes it (D144) and a payload passed on copies, with no `move g`.
enum H[T]:
    X(t: T)
    Y
enum G[T]:
    A(h: H[T])
    B(n: i64)

fn show_h(h: H[i64]) -> str:
    match h:
        H.X(t) => f"X {t}"
        H.Y => "Y"

fn show(g: G[i64]):
    match g:
        G.A(h) => print(show_h(h))
        G.B(n) => print(f"B {n}")

fn main:
    let g: G[i64] = G.A(H.X(3))
    show(g)
    show(G.B(7))
    show(g)
