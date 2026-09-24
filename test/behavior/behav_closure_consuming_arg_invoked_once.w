//! expect-stdout: abc
//! expect-stdout: xyz

// D63 (§12.4): a consuming closure may be handed to a callee that invokes
// its parameter at most once — an `if`/`else` pair is at most once.
fn pick(f: fn() -> str, g: fn() -> str, first: bool) -> str:
    if first: f() else: g()

fn main:
    let a = "abc".clone()
    let b = "xyz".clone()
    print(pick(() => a, () => b, true))
    let c = "abc".clone()
    let d = "xyz".clone()
    print(pick(() => c, () => d, false))
