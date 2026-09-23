//! expect-stdout: eval=-2222222222222
//! expect-stdout: eval=-2222222222225
//! expect-stdout: size-ok
//! expect-stdout: ok

// #1430: bodies are now defined when first referenced, and a reference to a
// body still being defined is legal only through an indirection. Two enums
// that hold each other through Box stay legal in either declaration order —
// Box is a pointer, so neither body waits on the other — and their layouts
// match the pair declared the other way round.

use std.box.Box

enum Expr:
    Num(n: i64)
    Neg(e: Box[Expr2])

fn eval(e: Expr) -> i64:
    match e:
        Expr.Num(n) => n
        Expr.Neg(inner) => 0 - eval2(inner.into_inner())

fn eval2(e: Expr2) -> i64:
    match e:
        Expr2.Lit(v, w) => v + w
        Expr2.Wrap(inner) => eval(inner.into_inner()) * 2

enum Expr2:
    Lit(v: i64, w: i64)
    Wrap(e: Box[Expr])

enum FirstB:
    Lit(v: i64, w: i64)
    Wrap(e: Box[FirstA])

enum FirstA:
    Num(n: i64)
    Neg(e: Box[FirstB])

fn main:
    print(f"eval={eval(Expr.Neg(Box.new(Expr2.Wrap(Box.new(Expr.Num(1111111111111))))))}")
    print(f"eval={eval(Expr.Neg(Box.new(Expr2.Lit(2222222222222, 3))))}")
    if size_of[Expr]() == size_of[FirstA]() and size_of[Expr2]() == size_of[FirstB]():
        print("size-ok")
    print("ok")
