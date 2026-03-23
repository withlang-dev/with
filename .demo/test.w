fn main:
    let a: f32 = 1.5
    let b: f32 = 2.5
    let c = a * b
    println(c)         // expect 3.75

    let d: f64 = c as f64
    println(d)         // expect 3.75