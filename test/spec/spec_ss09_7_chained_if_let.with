// Spec test: Section 9.7 — Chained if let (formerly 25.94)

type User { name: str, active: bool }

// PASS: chained if let bindings
fn test_chained_if_let_bindings:
    let a: Option[i32] = Some(1)
    let b: Option[i32] = Some(2)
    var result = 0
    if let Some(x) = a, let Some(y) = b:
        result = x + y
    assert(result == 3)

// PASS: chain fails if any binding fails
fn test_chained_if_let_short_circuits:
    let a: Option[i32] = Some(1)
    let b: Option[i32] = None
    var result = 0
    if let Some(x) = a, let Some(y) = b:
        result = x + y
    assert(result == 0)

// PASS: mixed boolean and let bindings
fn test_chained_if_let_mixed_boolean:
    let maybe_user: Option[User] = Some(User { name: "Alice", active: true })
    if let Some(user) = maybe_user, user.active:
        assert(user.name == "Alice")
