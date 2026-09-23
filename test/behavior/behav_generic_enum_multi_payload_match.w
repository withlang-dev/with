//! expect-stdout: t=7 k=8
//! expect-stdout: t=1 k=2
//! expect-stdout: owned/3
//! expect-stdout: both 5 five
//! expect-stdout: left 6
//! expect-stdout: 6
//! expect-stdout: true false
//! expect-stdout: xy

// #1441: matching a generic enum variant with two or more payload fields.
// The payload places were undeclared and the MIR validator, which cannot
// substitute a user generic's parameters, found no type for `t` in
// `G[i64].V(t: T, k: i64)`; codegen then found no payload struct for the
// instance's variant. Matrix: one and two type parameters, three payloads,
// by-value / `&` subjects, a literal payload pattern, an owned str payload,
// qualified and shorthand patterns, fn arguments and returns.

enum G[T]:
    V(t: T, k: i64)
    E

enum P[A, B]:
    Both(a: A, b: B)
    Left(a: A)
    Neither

enum Tri[T]:
    Three(x: T, y: T, z: T)
    Zero

fn g_text(g: G[i64]) -> str:
    match g:
        G.V(t, k) => f"t={t} k={k}"
        G.E => "E".clone()

fn g_ref_text(g: &G[str]) -> str:
    match g:
        .V(t, k) => f"{t}/{k}"
        .E => "E".clone()

fn p_text(p: P[i32, str]) -> str:
    match p:
        .Both(a, b) => f"both {a} {b}"
        .Left(a) => f"left {a}"
        .Neither => "neither".clone()

fn tri_sum(t: Tri[i64]) -> i64:
    match t:
        .Three(x, y, z) => x + y + z
        .Zero => 0

fn first_is_seven(g: G[i64]) -> bool:
    match g:
        G.V(7, _) => true
        _ => false

fn main:
    let g: G[i64] = G.V(7, 8)
    match g:
        G.V(t, k) => print(f"t={t} k={k}")
        G.E => print("E")
    print(g_text(G.V(1, 2)))
    let gs: G[str] = G.V("owned".clone(), 3)
    print(g_ref_text(gs))
    print(p_text(P.Both(5, "five".clone())))
    print(p_text(P.Left(6)))
    print(tri_sum(Tri.Three(1, 2, 3)))
    print(f"{first_is_seven(G.V(7, 0))} {first_is_seven(G.V(8, 0))}")
    let dropped: P[str, str] = P.Both("x".clone(), "y".clone())
    match dropped:
        .Both(a, b) => print(a ++ b)
        _ => print("other")
