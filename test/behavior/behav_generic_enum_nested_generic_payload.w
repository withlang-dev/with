//! expect-stdout: X 3
//! expect-stdout: X 4
//! expect-stdout: B 5
//! expect-stdout: X owned
//! expect-stdout: just 7
//! expect-stdout: just 8
//! expect-stdout: many 2
//! expect-stdout: pair 9

// #1442: a generic enum whose payload is another generic type instantiated
// with the same parameter, bound in a match. `G[T]: A(h: H[T])` has Option's
// shape (one parameter, a single-payload variant), and the MIR validator
// guessed the payload of `G[i64].A` to be `i64`, not `H[i64]`. Matrix: H[T]
// by value and through `&` (i64 and owned str), a user `Maybe[T]` (the shape
// the guess was for), Maybe[T] / Vec[T] / (T, T) payloads of one enum.

enum H[T]:
    X(t: T)
    Y

enum G[T]:
    A(h: H[T])
    B(n: i64)

enum Maybe[T]:
    Just(v: T)
    Nothing

enum Wrap[T]:
    One(m: Maybe[T])
    Many(v: Vec[T])
    Pair(p: (T, T))

fn show_h(h: H[i64]) -> str:
    match h:
        H.X(t) => f"X {t}"
        H.Y => "Y".clone()

fn show_hs(h: &H[str]) -> str:
    match h:
        .X(t) => f"X {t}"
        .Y => "Y".clone()

fn g_text(g: G[i64]) -> str:
    match g:
        G.A(h) => show_h(h)
        G.B(n) => f"B {n}"

fn gs_text(g: &G[str]) -> str:
    match g:
        .A(h) => show_hs(h)
        .B(n) => f"B {n}"

fn maybe_text(m: Maybe[i64]) -> str:
    match m:
        .Just(v) => f"just {v}"
        .Nothing => "nothing".clone()

fn wrap_text(w: Wrap[i64]) -> str:
    match w:
        .One(m) => maybe_text(m)
        .Many(v) => f"many {v.len()}"
        .Pair(p) => f"pair {p.0 + p.1}"

fn main:
    let g: G[i64] = G.A(H.X(3))
    match g:
        G.A(h) => print(show_h(h))
        G.B(n) => print(f"B {n}")
    print(g_text(G.A(H.X(4))))
    print(g_text(G.B(5)))
    let gs: G[str] = G.A(H.X("owned".clone()))
    print(gs_text(gs))
    print(maybe_text(Maybe.Just(7)))
    print(wrap_text(Wrap.One(Maybe.Just(8))))
    let xs: Vec[i64] = Vec.new()
    xs.push(1)
    xs.push(2)
    print(wrap_text(Wrap.Many(xs)))
    print(wrap_text(Wrap.Pair((4, 5))))
