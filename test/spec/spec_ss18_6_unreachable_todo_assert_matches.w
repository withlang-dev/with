//! skip: non-executable spec sketch for Section 18.6 — Unreachable, Todo, Assert_matches (formerly 25.49); contains pseudo-code for unimplemented feature work
// Spec test: Section 18.6 — Unreachable, Todo, Assert_matches (formerly 25.49)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: unreachable() has type Never
enum Direction { North | South | East | West }
fn go(d: Direction) -> i32:
    match d:
        .North => 1
        .South => 2
        .East  => 3
        .West  => 4
        _      => unreachable()

// PASS: todo() compiles but panics at runtime
fn future_feature(x: i32) -> str:
    todo("implement after v2")

// PASS: assert_matches with enum pattern
fn test:
    let r: Result[i32, str] = Err("not found")
    assert_matches(r, Err(_))

// PASS: assert_matches with nested pattern
enum AppError { Db(DbError) | Auth(str) }
enum DbError { NotFound(str, str) | Timeout }
fn test:
    let e = AppError.Db(DbError.NotFound("users", "42"))
    assert_matches(e, .Db(.NotFound(..)))

// PASS: assert_eq shows both values on failure
fn test:
    assert_eq(2 + 2, 4)
    assert_ne(2 + 2, 5)
