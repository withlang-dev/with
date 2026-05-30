// Spec test: Section 18.6 — Unreachable, Todo, Assert_matches (formerly 25.49)

enum Direction { North | South | East | West }

// PASS: unreachable() has type Never and is usable as a match fallback.
fn go(d: Direction) -> i32:
    match d:
        .North => 1
        .South => 2
        .East  => 3
        .West  => 4
        _      => unreachable()

fn test_unreachable_as_never:
    assert(go(Direction.North) == 1)
    assert(go(Direction.West) == 4)

// PASS: todo() compiles (it panics at runtime if ever called).
fn future_feature(x: i32) -> str:
    todo("implement after v2")

fn test_todo_compiles:
    // future_feature is defined above using todo(); compiling this file is the
    // coverage. We do not call it (it would panic).
    assert(true)

enum DbError { NotFound(str, str) | Timeout }
enum AppError { Db(DbError) | Auth(str) }

// PASS: assert_matches with an enum pattern.
fn test_assert_matches_enum:
    let r: Result[i32, str] = Err("not found")
    assert_matches(r, Err(_))

// PASS: assert_matches with a nested pattern.
// NOTE: the spec writes `.Db(.NotFound(..))`; the `..` rest pattern in tuple
// variants is tracked separately (#305), so explicit wildcards are used here.
fn test_assert_matches_nested:
    let e = AppError.Db(DbError.NotFound("users", "42"))
    assert_matches(e, .Db(.NotFound(_, _)))

// PASS: assert_eq / assert_ne.
fn test_assert_eq_ne:
    assert_eq(2 + 2, 4)
    assert_ne(2 + 2, 5)
