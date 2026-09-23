// §12.4: a non-move closure holds `n` by place; a read through the capture
// copies the value, and the closure only reads, so `n` is unchanged after.

fn apply(f: fn(i32) -> i32, x: i32) -> i32: f(x)

fn main:
    var n = 10
    let result = apply(
        (x: i32) =>
            n + x   // reads through the capture of n
        , 5)
    assert(result == 15)
    assert(n == 10)   // only read
    print("ok\n")
