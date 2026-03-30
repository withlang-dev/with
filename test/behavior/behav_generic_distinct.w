//! expect-stdout: ok

fn check_vec_i32:
    var v: Vec[i32] = Vec.new()
    v.push(42)
    v.push(99)
    assert(v.get(0) == 42)
    assert(v.get(1) == 99)
    assert(v.len() == 2)

fn check_vec_str:
    var v: Vec[str] = Vec.new()
    v.push("hello")
    v.push("world")
    assert(v.get(0) == "hello")
    assert(v.get(1) == "world")
    assert(v.len() == 2)

fn check_both:
    // Ensure Vec[i32] and Vec[str] coexist without type confusion
    var ints: Vec[i32] = Vec.new()
    var strs: Vec[str] = Vec.new()
    ints.push(1)
    ints.push(2)
    strs.push("a")
    strs.push("b")
    assert(ints.len() == 2)
    assert(strs.len() == 2)
    assert(ints.get(0) == 1)
    assert(ints.get(1) == 2)
    assert(strs.get(0) == "a")
    assert(strs.get(1) == "b")

fn check_hashmap:
    var m: HashMap[str, i32] = HashMap.new()
    m.insert("x", 10)
    m.insert("y", 20)
    assert(m.get("x").unwrap() == 10)
    assert(m.get("y").unwrap() == 20)

fn main:
    check_vec_i32()
    check_vec_str()
    check_both()
    check_hashmap()
    print("ok")
