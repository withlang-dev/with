//! expect-stdout: hello
//! expect-stdout: world
fn main:
    var v: List[str] = List.new()
    v.push("hello")
    v.push("world")
    for s in v:
        print(s)
