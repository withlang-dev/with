// Test float casting
fn main() -> i32 =
    let x: f64 = 3.14
    let y = x as i32
    println(y)

    let a: i32 = 42
    let b = a as f64
    // Print should show 42 (float formatting)
    let c = b as i32
    println(c)

    // Float to float
    let d: f64 = 2.5
    let e = d as f32
    let f = e as f64
    let g = f as i32
    println(g)
    0
