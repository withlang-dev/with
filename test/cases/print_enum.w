// Test: println support for enum types
type Color = Red | Green | Blue
type Shape = Circle(i32) | Rectangle(i32)

fn main -> i32:
    let c = Red
    println(c)
    let s = Circle(5)
    println(s)
    let r = Rectangle(10)
    println(r)
