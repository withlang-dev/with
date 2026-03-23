//! expect-stdout: ok

// Behavior test: references and borrowing
// Tests: pass by reference, dereferencing, &x syntax

type Point = { x: i32, y: i32 }

fn read_x(p: &Point) -> i32:
    p.x

fn read_y(p: &Point) -> i32:
    p.y

fn sum_coords(p: &Point) -> i32:
    p.x + p.y

fn test_pass_by_ref:
    let p = Point { x: 10, y: 20 }
    assert(read_x(&p) == 10)
    assert(read_y(&p) == 20)
    assert(sum_coords(&p) == 30)

fn test_ref_multiple_reads:
    let p = Point { x: 3, y: 7 }
    // Multiple shared borrows are allowed
    let a = read_x(&p)
    let b = read_y(&p)
    assert(a == 3)
    assert(b == 7)

fn add_points(a: &Point, b: &Point) -> Point:
    Point { x: a.x + b.x, y: a.y + b.y }

fn test_multiple_refs:
    let p1 = Point { x: 1, y: 2 }
    let p2 = Point { x: 3, y: 4 }
    let p3 = add_points(&p1, &p2)
    assert(p3.x == 4)
    assert(p3.y == 6)

fn test_ref_after_use:
    let p = Point { x: 100, y: 200 }
    let s1 = sum_coords(&p)
    let s2 = sum_coords(&p)
    assert(s1 == s2)
    assert(s1 == 300)

fn main:
    test_pass_by_ref()
    test_ref_multiple_reads()
    test_multiple_refs()
    test_ref_after_use()
    println("ok")
