// NEGATIVE: f64 → f32 implicit narrowing should be rejected (§4.2)
// EXPECT: check fails with narrowing error
fn main -> i32:
    let f: f64 = 3.14
    let g: f32 = f
    0
