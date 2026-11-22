//! expect-stdout: ok
// Test List[T].new() syntax — specifying element type at construction

fn main:
    var v = List[i32].new()
    v.push(10)
    v.push(20)
    v.push(30)
    assert(v.len() == 3)
    assert(v[0] == 10)
    assert(v[2] == 30)

    var names = List[str].new()
    names.push("alice")
    names.push("bob")
    assert(names.len() == 2)
    assert(names[0] == "alice")

    print("ok")
