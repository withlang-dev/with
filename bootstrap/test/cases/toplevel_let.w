// Test top-level let/var declarations
let MAX: i32 = 100
let PI_VAL: f64 = 3.14
let GREETING = "hello"
let FLAG: bool = true

fn double(x: i32) -> i32: x * 2

fn main -> i32:
    println(MAX)
    println(double(MAX))
    println(PI_VAL)
    println(GREETING)
    println(FLAG)
