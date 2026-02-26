// Test nested constructor patterns: Some(Some(v)), Some(None), etc.

fn make_some_some(x: i32) -> Option[Option[i32]]:
    let inner: Option[i32] = Some(x)
    Some(inner)

fn make_some_none -> Option[Option[i32]]:
    let inner: Option[i32] = None
    Some(inner)

fn make_none -> Option[Option[i32]]:
    None

fn test_match(x: Option[Option[i32]]) -> i32:
    match x
        Some(Some(v)) -> v
        Some(None) -> -1
        None -> -2

fn main -> i32:
    let a = test_match(make_some_some(42))
    let b = test_match(make_some_none())
    let c = test_match(make_none())
    if a == 42 and b == -1 and c == -2
        0
    else
        1
