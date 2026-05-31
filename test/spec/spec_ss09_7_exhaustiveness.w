// Spec test: Section 9.7 — Exhaustiveness

enum Color:
    Red
    Green
    Blue

fn name(c: Color) -> str:
    match c:
        .Red => "red"
        .Green => "green"
        .Blue => "blue"

fn name_wildcard(c: Color) -> str:
    match c:
        .Red => "red"
        _ => "other"

fn test_exhaustive_all_variants:
    assert(name(Color.Green) == "green")

fn test_wildcard_arm:
    assert(name_wildcard(Color.Blue) == "other")
