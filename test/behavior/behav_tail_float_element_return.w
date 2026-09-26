//! expect-stdout: 3.5 2.25 0.75
//! expect-stdout: 1.5 6.5
//! expect-stdout: ok

// D27 / #1714: `xs[i]` is the element view `&T`; a declared `-> f64` is an
// owned demand, so a tail element materializes its Copy pointee exactly as
// `return xs[i]` does. arithmetic_result_type answered `f64` for `f64`
// against `&f64`, so the tail looked compatible, no contextual Copy was
// recorded, and the element's address reached the f64 return slot
// (invalid MIR before codegen). Integer elements never took that branch.

fn tail(xs: &Vec[f64]) -> f64:
    xs[0]

fn local -> f64:
    var xs: Vec[f64] = Vec.new()
    xs.push(9.0)
    xs.push(2.25)
    xs[1]

fn median(xs: &Vec[f64]) -> f64:
    let n = xs.len() as i32
    xs[n / 2]

fn narrow(xs: &Vec[f32]) -> f32:
    xs[1]

fn pick(xs: &Vec[f64], first: bool) -> f64:
    if first: xs[0] else: xs[1]

fn main:
    var xs: Vec[f64] = Vec.new()
    xs.push(3.5)
    xs.push(6.5)
    xs.push(0.75)
    var ys: Vec[f32] = Vec.new()
    ys.push(0.5)
    ys.push(1.5)
    print(f"{tail(&xs)} {local()} {median(&xs) - 5.75}")
    print(f"{narrow(&ys)} {pick(&xs, false)}")
    assert(pick(&xs, true) == 3.5)
    print("ok")
