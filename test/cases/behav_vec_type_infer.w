//! expect-stdout: ok
// Test Vec[T].new() syntax — specifying element type at construction

fn main:
    var v = Vec[i32].new()
    v.push(10)
    v.push(20)
    v.push(30)
    assert(v.len() == 3)
    assert(v.get(0) == 10)
    assert(v.get(2) == 30)

    var names = Vec[str].new()
    names.push("alice")
    names.push("bob")
    assert(names.len() == 2)
    assert(names.get(0) == "alice")

    print("ok")
