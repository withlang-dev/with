// Spec test: Section 9.7 — Destructuring Let
// Executable subset: tuple destructuring (struct `let { x, y } = p` not yet supported).

fn test_tuple_destructure:
    let (a, b, c) = (1, 2, 3)
    assert(a + b + c == 6)

fn test_nested_tuple_destructure:
    let (x, (y, z)) = (1, (2, 3))
    assert(x + y + z == 6)
