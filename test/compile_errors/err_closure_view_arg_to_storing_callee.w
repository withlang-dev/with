//! expect-check-fail: stores or returns its parameter

// D63 (§12.4): a non-move closure argument is ephemeral in the callee
// exactly as a `&T` parameter is — it may be invoked and passed on, not
// stored or returned. `keep` returns its parameter (ESCAPE_VALUE), so a
// closure holding `xs` by place may not reach it; `move () => ...` may.
fn keep(f: fn() -> i32) -> fn() -> i32: f

fn main:
    var xs: Vec[i32] = Vec.new()
    let g = keep(() => xs.len32())
    print(g())
