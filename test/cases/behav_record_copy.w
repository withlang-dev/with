//! expect-stdout: ok

// Behavior test: struct construction, field access, and record update

type Point = {
    x: i32,
    y: i32,
}

fn test_struct_construction:
    let p = Point { x: 10, y: 20 }
    assert(p.x == 10)
    assert(p.y == 20)

fn test_struct_field_arithmetic:
    let p = Point { x: 5, y: 7 }
    let sum = p.x + p.y
    assert(sum == 12)

fn test_record_update:
    let p = Point { x: 1, y: 2 }
    let p2 = { p with x: 100 }
    assert(p2.x == 100)
    assert(p2.y == 2)

fn test_record_update_both:
    let p = Point { x: 3, y: 4 }
    let p2 = { p with x: 30, y: 40 }
    assert(p2.x == 30)
    assert(p2.y == 40)

fn test_copy_semantics:
    // Primitive types (i32, bool) are copy
    let a = 42
    let b = a
    assert(a == 42)
    assert(b == 42)
    let t = true
    let f = t
    assert(t)
    assert(f)

fn main:
    test_struct_construction()
    test_struct_field_arithmetic()
    test_record_update()
    test_record_update_both()
    test_copy_semantics()
    println("ok")
