//! expect-stdout: ok

// Test: @[must_use] type-level tracking enforces exhaustive match.
// - Must-use types require exhaustive match even in statement position
// - Wildcard arm satisfies exhaustiveness
// - Non-must-use types allow partial match in statement position
// - Result allows partial statement-position matches; unmatched variants are no-op

@[must_use]
enum Status { Ok | Err }

enum Color { Red | Green | Blue }

fn test_must_use_exhaustive_match:
    // Must-use type with exhaustive match (all variants covered) — ok
    let s: Status = .Ok
    match s:
        .Ok => print("ok status")
        .Err => print("err status")

fn test_must_use_with_wildcard:
    // Must-use type with wildcard — ok (wildcard counts as catch-all)
    let s: Status = .Ok
    match s:
        .Ok => print("ok status")
        _ => print("other")

fn test_non_must_use_partial:
    // Non-must-use type with partial match in statement position — ok
    let c: Color = .Red
    match c:
        .Red => print("red")

fn fallible(n: i32) -> Result[i32, str]:
    if n > 0:
        Ok(n)
    else:
        Err("neg")

fn test_result_partial_statement_match:
    match fallible(1):
        Ok(v) => assert(v == 1)
    match fallible(-1):
        Ok(_) => assert(false, "unreachable")

fn main:
    test_must_use_exhaustive_match()
    test_must_use_with_wildcard()
    test_non_must_use_partial()
    test_result_partial_statement_match()
    print("ok")
