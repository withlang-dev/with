//! expect-stdout: ok

// Tests: :? debug mode for structs

type Point = {
    x: i32,
    y: i32,
}

fn test_debug_struct_basic:
    let p = Point { x: 10, y: 20 }
    let s = f"{p:?}"
    assert(s == "Point { x: 10, y: 20 }")

type Named = {
    name: str,
    value: i32,
}

fn test_debug_struct_with_str:
    let n = Named { name: "test", value: 42 }
    let s = f"{n:?}"
    assert(s == "Named { name: test, value: 42 }")

fn test_debug_struct_in_context:
    let p = Point { x: 1, y: 2 }
    assert(f"pos={p:?}" == "pos=Point { x: 1, y: 2 }")

fn main:
    test_debug_struct_basic()
    test_debug_struct_with_str()
    test_debug_struct_in_context()
    println("ok")
