//! expect-stdout: ok

// Tests: nested struct debug formatting

type Vec2 = {
    x: i32,
    y: i32,
}

type Player = {
    name: str,
    score: i32,
}

fn test_nested_struct_with_primitives:
    let p = Player { name: "alice", score: 42 }
    let s = f"{p:?}"
    assert(s == "Player { name: alice, score: 42 }")

fn test_simple_vec2:
    let v = Vec2 { x: 1, y: 2 }
    assert(f"{v:?}" == "Vec2 { x: 1, y: 2 }")

fn main:
    test_nested_struct_with_primitives()
    test_simple_vec2()
    println("ok")
