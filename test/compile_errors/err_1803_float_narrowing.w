//! expect-error: implicit float narrowing from `f64` to `f32`

// §4.2.6 (#1803): no implicit numeric conversion but a lossless widening.
// `let g: f32 = f` with `f: f64` converted silently.
fn main:
    let f: f64 = 3.7
    let g: f32 = f
    print(f"{g}")
