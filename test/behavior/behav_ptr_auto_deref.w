//! expect-stdout: ok

// Tests: auto-deref for pointer field access (*mut T → T.field)

type Point = {
    x: i32,
    y: i32,
}

type Node = {
    value: i32,
    label: str,
}

unsafe fn read_point_fields(p: *const Point) -> i32:
    p.x + p.y

unsafe fn write_point_field(p: *mut Point, v: i32):
    p.x = v

unsafe fn read_node_fields(p: *const Node) -> str:
    p.label

fn test_auto_deref_read:
    let pt = Point { x: 10, y: 20 }
    let p = &pt as *const Point
    let sum = unsafe: read_point_fields(p)
    assert(sum == 30)

fn test_auto_deref_write:
    var pt = Point { x: 0, y: 5 }
    let p = &mut pt as *mut Point
    unsafe: write_point_field(p, 42)
    assert(pt.x == 42)
    assert(pt.y == 5)

fn test_auto_deref_str_field:
    let n = Node { value: 1, label: "hello" }
    let p = &n as *const Node
    let s = unsafe: read_node_fields(p)
    assert(s == "hello")

fn test_auto_deref_ref:
    // Also works through &T and &mut T
    let pt = Point { x: 3, y: 7 }
    let r = &pt
    assert(r.x == 3)
    assert(r.y == 7)

fn main:
    test_auto_deref_read()
    test_auto_deref_write()
    test_auto_deref_str_field()
    test_auto_deref_ref()
    println("ok")
