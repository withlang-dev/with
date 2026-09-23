//! expect-debug-alloc: leak count=0
// #1442: a generic enum carrying another generic enum instantiated with the
// same parameter, with an owned str inside: bound by value and passed on,
// bound through a reference, dropped whole. Each str is freed exactly once.

enum H[T]:
    X(t: T)
    Y

enum G[T]:
    A(h: H[T])
    B(n: i64)

fn inner(h: H[str]) -> i64:
    match h:
        H.X(t) => t.len()
        H.Y => 0

fn outer(g: G[str]) -> i64:
    match g:
        G.A(h) => inner(h)
        G.B(n) => n

fn peek(g: &G[str]) -> i64:
    match g:
        .A(h) => match h:
            .X(t) => t.len()
            .Y => 0
        .B(n) => n

fn main:
    print(outer(G.A(H.X("four".clone()))))
    let kept: G[str] = G.A(H.X("seven!!".clone()))
    print(peek(kept))
    let whole: G[str] = G.A(H.X("dropped".clone()))
    print(peek(whole))
