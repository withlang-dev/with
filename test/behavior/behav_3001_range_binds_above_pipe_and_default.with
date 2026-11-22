//! expect-stdout: 0 2 4
//! expect-stdout: 6
//! expect-stdout: 1 2
//! expect-stdout: 2 3 4
//! expect-stdout: 0 1 2 3
// #3001 (§9.9, D192): a range binds above `|>` and `??` and below the
// operators that compute its bounds, so `0..3 |> map(f)` pipes the range,
// `0..n + 1` is `0..(n + 1)`, and a subscript's `xs[a..b]` is still the slice.
fn main:
    var doubled = ""
    for x in 0..3 |> map(it * 2): doubled = doubled ++ f"{x} "
    print(doubled.trim())
    print(0..4 |> map(it) |> sum())
    let xs = [0, 1, 2, 3, 4]
    let s = xs[1..3]
    print(f"{s[0]} {s[1]}")
    let n = 3
    var out = ""
    for v in 2..n + 2: out = out ++ f"{v} "
    print(out.trim())
    let tail = xs[0..]
    print(f"{tail[0]} {tail[1]} {tail[2]} {tail[3]}")
