//! expect-stdout: trait 4 5
//! expect-stdout: async 6 hi!
//! expect-stdout: generic 4 x!
//! expect-stdout: brace 2
//! expect-stdout: unsafe 5

// §9.1 / D60: every way a body gets a declared non-`Unit` return makes its
// tail assignment the body's value — a read of the place after the store:
// a trait method's contract (the impl need not repeat `-> i32`), an
// `async fn`'s result (the body is typed against `T` in `Task[T]`), a
// generic return, the brace body form, and an `unsafe fn` (its implicit
// unsafe block is not a second body).

trait Bump:
    mut fn bump() -> i32

type B { n: i32 }

impl Bump for B:
    mut fn bump(): self.n += 1

async fn inc(k: i32) -> i32:
    var n = k
    n += 1

async fn name -> str:
    var s = "".clone()
    s = "hi".clone() ++ "!"

fn keep[T](x: T) -> T:
    var y = x
    y = y

fn brace -> i32 {
    var n = 1
    n += 1
}

unsafe fn store(p: *mut i32, v: i32) -> i32: *p = v

fn main:
    var b = B { n: 3 }
    let first = b.bump()
    print(f"trait {first} {b.bump()}")
    let n = inc(5).await
    let s = name().await
    print(f"async {n} {s}")
    let k = keep(4)
    let ks = keep("x".clone() ++ "!")
    print(f"generic {k} {ks}")
    print(f"brace {brace()}")
    var cell = 0
    let got = unsafe { store(&raw mut cell, 5) }
    print(f"unsafe {got}")
