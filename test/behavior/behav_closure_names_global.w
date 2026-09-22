//! expect-stdout: ok

// #1313: a closure that names a global is not capturing it. A global is a
// place every body references in place (§9.1c, D52: globals are never moved
// out of), so the closure reads and writes the module's `var` itself; the
// old capture list handed MirLower a symbol with no local and it panicked
// ("anonymous capture lacks a concrete local type"). A single-threaded
// program, so the §9.1c race proof holds for every access below.

var g: i32 = 0
var log: str = ""

fn apply(f: fn() -> i32) -> i32: f()

fn main:
    // A read of the global.
    let read: fn() -> i32 = () => g + 1
    assert(read() == 1)
    g = 41
    assert(read() == 42)

    // Assignment and compound assignment through the closure reach the
    // global, not a copy.
    let bump: fn() -> Unit = () => g += 10
    bump()
    assert(g == 51)
    let reset: fn() -> Unit = () => { g = 3 }
    reset()
    assert(g == 3)

    // A local capture alongside the global: the local is the closure's one
    // capture; the global stays the global.
    var n = 100
    let both: fn() -> i32 = () => n + g
    assert(apply(both) == 103)
    g = 4
    assert(both() == 104)

    // A non-Copy global: naming it moves nothing out of the module.
    let tag: fn() -> Unit = () => { log = log ++ "x" }
    tag()
    tag()
    assert(log == "xx")
    assert(log.len() == 2)
    print("ok")
