//! expect-stdout: 42
//! expect-stdout: hello
type Point { x: i32, y: i32 }

fn main:
    let p = Point { x: 42, y: 10 }
    print(int_to_string(p.x))
    print("hello")
