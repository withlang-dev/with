//! expect-stdout: match 1 2 3
//! expect-stdout: generic 4 5 6
//! expect-stdout: vector 4 5 5
//! expect-stdout: drop hello 7 8
//! expect-stdout: none ok

// #1964: an enum variant with several payload fields lays them out as a
// struct (with-abi.md §2) — each field at the model's alignment for it, the
// same placement a tuple takes. The payload's LLVM body was the literal
// struct of the field types, so an `@[align(N)]` record (LLVM-aligned 1,
// §16.4) or a `Vector[8, f32]` (LLVM-aligned 32 where §4.3d caps AArch64 at
// 16) landed at LLVM's offset: `F.A(4, V8.splat(5))` wrote a 64-byte
// payload into a 48-byte area and read `4 0 0` back.

type Al { a: i8, @[align(32)] b: i64 }
type V8 = Vector[8, f32]

enum E { A(k: i8, al: Al) | B }
enum F { A(k: i8, v: V8) | B }
enum G[T] { A(k: i8, t: T) | B }
enum D { A(al: Al, s: str) | B }

fn mk(k: i8) -> E: E.A(k, Al { a: 2, b: 3 })

fn main:
    match mk(1):
        .A(k, al) => print(f"match {k} {al.a} {al.b}")
        .B => print("match b")
    let g: G[Al] = G.A(4, Al { a: 5, b: 6 })
    match g:
        .A(k, t) => print(f"generic {k} {t.a} {t.b}")
        .B => print("generic b")
    let f = F.A(4, V8.splat(5))
    match f:
        .A(k, v) => print(f"vector {k} {v[0]} {v[7]}")
        .B => print("vector b")
    let d = D.A(Al { a: 7, b: 8 }, "hello")
    match d:
        .A(al, s) => print(f"drop {s} {al.a} {al.b}")
        .B => print("drop b")
    let n: F = F.B
    match n:
        .A(_, _) => print("none bad")
        .B => print("none ok")
