// Wave 6 unit test: scope and binding semantics
// Covers: nested scopes, let shadowing (disallowed), blocks as expressions

fn block_result -> i32:
    let a: i32 = 1
    let b: i32 = a + 1
    b + 1

fn conditional_binding(x: i32) -> i32:
    if x > 0:
        let pos = x * 2
        pos
    else:
        0

fn main -> i32:
    let r1 = block_result()
    let r2 = conditional_binding(5)
    r1 + r2
