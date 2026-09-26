//! expect-stdout: 1

// §12.4: a local consumed with an explicit `move` argument inside the body
// is captured (the walk descends NK_MOVE_ARG / NK_COPY_ARG).
fn take(v: Vec[i32]) -> i32: v.len() as i32
fn run(f: fn() -> i32) -> i32: f()
fn main:
    var v: Vec[i32] = Vec.new()
    v.push(7)
    print(run(move () => take(move v)))
