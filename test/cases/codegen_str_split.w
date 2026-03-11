//! expect-stdout: 3
//! expect-stdout: hello
//! expect-stdout: world
//! expect-stdout: foo
fn main:
    let s = "hello,world,foo"
    let parts = s.split(",")
    println(int_to_string(parts.len() as i32))
    for i in 0..parts.len():
        let p = parts.get(i)
        println(p)
