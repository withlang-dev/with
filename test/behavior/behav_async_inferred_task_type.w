//! expect-stdout: 10 42
//! expect-stdout: 2 n2
//! expect-stdout: 7 xy
//! expect-stdout: 16 6
//! expect-stdout: 5 20
//! expect-stdout: false
//! expect-stdout: ok

// #1464 (§14.2, §14.4): calling an `async fn` returns a `Task[T]` handle.
// An unannotated async fn's inferred return was stored as the bare T, so its
// calls were typed `i32`: the handle lived in i32-typed MIR locals, a method
// could not be awaited ("await requires a Task value"), a Task parameter or
// Vec[Task[i32]] refused it, and `.cancel()` aborted the compiler. Annotated
// async fns were always `Task[T]`.
use std.task.Task

type Payload { a: i64, s: str }
type S { n: i32 }

impl S:
    async fn get(): self.n + 1

async fn double(x: i32): x * 2
async fn name(n: i32): f"n{n}"
async fn mk(n: i64): Payload { a: n, s: "x" ++ "y" }
async fn inner(x: i32): x + 1
async fn outer(x: i32): inner(x).await * 10

fn wait(t: Task[i32]) -> i32: t.await

async fn fast(): 10
async fn slow(): 20

async fn main:
    let t1 = double(5)
    print(f"{t1.await} {double(21).await}")
    let (a, b) = (double(1), name(2)).await
    print(f"{a} {b}")
    let p = mk(7).await
    print(f"{p.a} {p.s}")
    var ts: Vec[Task[i32]] = Vec.new()
    ts.push(double(1))
    ts.push(double(2))
    var total = 0
    for t in ts.into_iter():
        total = total + t.await
    print(f"{wait(double(8))} {total}")
    let s = S { n: 4 }
    print(f"{s.get().await} {outer(1).await}")
    let c = double(5)
    c.cancel()
    print(c.was_cancelled())
    let f1 = fast()
    let f2 = slow()
    select await:
        r1 = f1 => assert(r1 == 10)
        r2 = f2 => assert(r2 == 20)
    print("ok")
