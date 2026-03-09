//! expect-stdout: ok

// Test: @[must_use] type-level tracking enforces exhaustive match.
// - Must-use types require exhaustive match even in statement position
// - Wildcard arm satisfies exhaustiveness
// - Non-must-use types allow partial match in statement position
// - Result (hardcoded must_use) requires exhaustive match

@[must_use]
type Status = Ok | Err

type Color = Red | Green | Blue

fn test_must_use_exhaustive_match:
    // Must-use type with exhaustive match (all variants covered) — ok
    let s: Status = .Ok
    match s
        .Ok -> println("ok status")
        .Err -> println("err status")

fn test_must_use_with_wildcard:
    // Must-use type with wildcard — ok (wildcard counts as catch-all)
    let s: Status = .Ok
    match s
        .Ok -> println("ok status")
        _ -> println("other")

fn test_non_must_use_partial:
    // Non-must-use type with partial match in statement position — ok
    let c: Color = .Red
    match c
        .Red -> println("red")

fn main:
    test_must_use_exhaustive_match()
    test_must_use_with_wildcard()
    test_non_must_use_partial()
    println("ok")
