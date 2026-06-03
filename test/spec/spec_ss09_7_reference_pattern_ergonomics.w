//! expect-stdout: ok
// Spec test: Section 9.7 - Reference Pattern Ergonomics.

type Point { x: i32, y: i32 }

fn describe(opt: &Option[str]) -> str:
    match opt:
        Some(s) => *s
        None => "none"

fn test_match_on_borrowed_option:
    let x: Option[str] = Some("hello")
    let y: Option[str] = None
    assert(describe(&x) == "hello")
    assert(describe(&y) == "none")

fn test_borrowed_tuple_let:
    let pair = (1, 2)
    let (a, b) = &pair
    assert(*a + *b == 3)

fn test_for_loop_destructuring_auto_borrows:
    let items: Vec[(i32, i32)] = Vec.new()
    items.push((1, 2))
    items.push((3, 4))

    var total = 0
    for (a, b) in items.iter_ref():
        total = total + *a + *b
    assert(total == 10)

fn test_nested_tuple_destructuring_through_reference:
    let nested = ((1, 2), 3)
    let ((a, b), c) = &nested
    assert(*a + *b + *c == 6)

fn test_borrowed_struct_pattern:
    let point = Point { x: 4, y: 5 }
    let { x, y } = &point
    assert(*x + *y == 9)

fn main:
    test_match_on_borrowed_option()
    test_borrowed_tuple_let()
    test_for_loop_destructuring_auto_borrows()
    test_nested_tuple_destructuring_through_reference()
    test_borrowed_struct_pattern()
    print("ok")
