//! expect-stdout: 16 32
//! expect-stdout: 4 8
//! expect-stdout: 24 1

// A `sizeof` type argument inside a monomorphized body names the
// instance's own substitution: `PC[G]` under `sz[G]`, and `T` under
// `PC.make[T]`. The C backend resolves it through Sema's record of the
// specialization (D65: Sema decided what `G` is), as the LLVM backend
// binds the same record, so two instances of one template size two
// different types. Before this the C emitter failed on `PC[G]`
// (emit-c-smoke, gen_pull's `sizeof[PullCore[G]]`) and sized every
// receiver instance's `T` as the last one checked: `Box.new` of an A
// then a B allocated sizeof(B) for the A.
use std.box.Box

type PC[T] { x: T, y: i64 }

fn PC.make[T](v: T) -> PC[T]: PC { x: v, y: sizeof[T]() as i64 }

fn sz[G](g: G) -> i64:
    sizeof[PC[G]]() as i64

type A { a: i64, b: i64, c: i64 }
type B { a: i8 }

fn main:
    print(f"{sz(3)} {sz(A { a: 1, b: 2, c: 3 })}")
    print(f"{PC.make(1).y} {PC.make(7 as i64).y}")
    let x = Box.new(A { a: 1, b: 2, c: 3 })
    let y = Box.new(B { a: 1 })
    print(f"{x.a + x.b + x.c + 18} {y.a}")
