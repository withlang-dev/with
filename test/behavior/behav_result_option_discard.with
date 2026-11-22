//! expect-stdout: ok

// §10.1: a bare expression-statement Result/Option is discarded with no
// ceremony (a dropped Result does nothing). The side effects still run.

var CALLS = 0

fn fallible(ok: bool) -> Result[i32, str]:
    CALLS = CALLS + 1
    if ok: Ok(1) else: Err("no")

fn maybe(some: bool) -> Option[i32]:
    CALLS = CALLS + 1
    if some: Some(1) else: None

fn main:
    fallible(true)
    fallible(false)
    maybe(true)
    maybe(false)
    assert(CALLS == 4)
    print("ok")
