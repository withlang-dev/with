//! expect-stdout: abc
//! expect-stdout: none
//! expect-stdout: x
//! expect-stdout: fwd
//! expect-stdout: run

// §12.4 (D75): `f: once fn(A) -> R` — the body invokes `f` at most once,
// so a consuming closure may be passed to it. Within one compilation `once`
// is permitted and checked but never required; a `once` parameter invoked
// never, once, from a closure that consumes nothing, forwarded to another
// `once` parameter, and on a method.
fn apply(f: once fn() -> str) -> str: f()

fn ignore(f: once fn() -> str) -> str: "none"

fn one(f: once fn() -> str) -> str: f()

fn forward(f: once fn() -> str) -> str: one(f)

type Runner { n: i32 }

impl Runner:
    fn run(f: once fn() -> str) -> str: f()

fn main:
    let s = "abc"
    print(apply(() => s))
    let unused = "unused"
    print(ignore(() => unused))
    print(apply(() => "x"))
    let fwd = "fwd"
    print(forward(() => fwd))
    let r = Runner { n: 1 }
    let word = "run"
    print(r.run(() => word))
