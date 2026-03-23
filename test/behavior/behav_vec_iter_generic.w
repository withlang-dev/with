//! expect-stdout: hello
//! expect-stdout: world
fn main:
    var v: Vec[str] = Vec.new()
    v.push("hello")
    v.push("world")
    for s in v:
        println(s)
