// Test: distinct types with operations
type Celsius = distinct i32
type Fahrenheit = distinct i32

fn to_fahrenheit(c: i32) -> i32:
    c * 9 / 5 + 32

fn main -> i32:
    let temp = 100
    let f = to_fahrenheit(temp)
    println(f)
    assert(f == 212)

    let freezing = to_fahrenheit(0)
    println(freezing)
    assert(freezing == 32)

