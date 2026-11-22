//! expect-stdout: ok
// §29: todo()/unreachable() are Never-typed; usable in value position and with
// an optional message; never called at runtime here.
fn maybe(n: i32) -> i32:
    if n > 0: n else: todo("negative case")
fn classify(n: i32) -> i32:
    let x: i32 = if n > 0: 1 else: unreachable()
    x
fn main:
    assert(maybe(5) == 5)
    assert(classify(1) == 1)
    print("ok")
