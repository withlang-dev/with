//! expect-stdout: 42 12 7
// #1305: `.await` loads the value its Task's own type argument names.
// Codegen's FIBER_AWAIT read it from a side table keyed by MIR local id
// (filled at each async spawn and never cleared between functions), then
// from the last spawn's type, then guessed i32. `helper`'s `t` is local _1,
// the same id as `warm`'s spawn of `num()`, so the str result was loaded as
// an i64 and `s.len()` crashed (exit 139). MIR has typed the call's result
// local as Task[T] since; the codegen audit's #1305 exclusion is retired.
use std.task

async fn num() -> i64: 42
async fn text() -> str: "hello, world"
async fn warm() -> i64: num().await

async fn helper(t: Task[str]) -> i64:
    let s = t.await
    s.len()

async fn pair(a: Task[i64], b: Task[str]) -> i64:
    let x = a.await
    let y = b.await
    x + y.len()

async fn main:
    let n = warm().await
    let m = helper(text()).await
    let p = pair(num(), fn_text("abc")).await
    print(f"{n} {m} {p - 38}")

async fn fn_text(s: str) -> str: s
