//! expect-stdout: 20

// §12.4: both the indexed collection and the index are captured.
fn run(f: fn() -> i32) -> i32: f()
fn main:
    let i = 1
    var xs: Vec[i32] = Vec.new()
    xs.push(10)
    xs.push(20)
    print(run(() => xs[i]))
