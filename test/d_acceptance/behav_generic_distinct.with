//! expect-stdout: ok

fn check_list_i32:
    var v: List[i32] = List.new()
    v.push(42)
    v.push(99)
    assert(v[0] == 42)
    assert(v[1] == 99)
    assert(v.len() == 2)

fn check_list_str:
    var v: List[str] = List.new()
    v.push("hello")
    v.push("world")
    assert(v[0] == "hello")
    assert(v[1] == "world")
    assert(v.len() == 2)

fn check_both:
    // Ensure List[i32] and List[str] coexist without type confusion
    var ints: List[i32] = List.new()
    var strs: List[str] = List.new()
    ints.push(1)
    ints.push(2)
    strs.push("a")
    strs.push("b")
    assert(ints.len() == 2)
    assert(strs.len() == 2)
    assert(ints[0] == 1)
    assert(ints[1] == 2)
    assert(strs[0] == "a")
    assert(strs[1] == "b")

fn check_hashmap:
    var m: HashMap[str, i32] = HashMap.new()
    m.insert("x", 10)
    m.insert("y", 20)
    assert(m.get("x").unwrap() == 10)
    assert(m.get("y").unwrap() == 20)

fn main:
    check_list_i32()
    check_list_str()
    check_both()
    check_hashmap()
    print("ok")
