// Spec test: Section 9.7 — Destructuring Let
//
// All pattern forms are available in `let` bindings: tuple and struct
// destructuring, field shorthand, `..` to ignore remaining fields, field
// renaming, and nested patterns.

type Point { x: i32, y: i32 }
type User { name: str, age: i32, active: bool }
type Line { a: Point, b: Point }

fn test_tuple_destructure:
    let (a, b, c) = (1, 2, 3)
    assert(a + b + c == 6)

fn test_nested_tuple_destructure:
    let (x, (y, z)) = (1, (2, 3))
    assert(x + y + z == 6)

// Struct destructuring with field shorthand.
fn test_struct_destructure:
    let p = Point { x: 3, y: 4 }
    let { x, y } = p
    assert(x + y == 7)

// `..` ignores the remaining fields.
fn test_struct_rest_fields:
    let u = User { name: "alice", age: 30, active: true }
    let { name, age, .. } = u
    assert(name == "alice")
    assert(age == 30)

// Fields can be renamed in the pattern.
fn test_struct_field_rename:
    let p = Point { x: 3, y: 4 }
    let { x: px, y: py } = p
    assert(px + py == 7)

// Whole-field bindings can be used afterwards.
fn test_struct_field_bindings:
    let l = Line { a: Point { x: 1, y: 2 }, b: Point { x: 3, y: 4 } }
    let { a, b } = l
    assert(a.x + b.y == 5)

// Nested struct patterns destructure recursively.
fn test_nested_struct_pattern:
    let l = Line { a: Point { x: 1, y: 2 }, b: Point { x: 3, y: 4 } }
    let { a: Point { x, y }, .. } = l
    assert(x + y == 3)
