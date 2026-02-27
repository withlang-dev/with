// POSITIVE: f32 → f64 implicit widening should succeed (§4.2)
fn main -> i32:
    let x: f64 = 3.14
    let f = x as f32
    let g: f64 = f
    println("float widen ok")
