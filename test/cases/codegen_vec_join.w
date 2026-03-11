//! expect-stdout: a,b,c
fn main:
    let v: Vec[str] = Vec.new()
    v.push("a")
    v.push("b")
    v.push("c")
    let result = v.join(",")
    println(result)
