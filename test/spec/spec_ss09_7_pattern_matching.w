//! skip: non-executable spec sketch for Section 9.7 — Pattern Matching (formerly 25.14); contains pseudo-code for unimplemented feature work
// Spec test: Section 9.7 — Pattern Matching (formerly 25.14)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: nested
enum Expr { Lit(i32) | Add(Expr, Expr) | Mul(Expr, Expr) }
fn simplify(e: Expr) -> Expr:
    match e:
        Add(Lit(0), rhs) => rhs
        Mul(Lit(0), _) | Mul(_, Lit(0)) => Lit(0)
        other => other

// PASS: or-patterns
fn classify(day: Day) -> str:
    match day:
        Monday | Tuesday | Wednesday | Thursday | Friday => "weekday"
        Saturday | Sunday => "weekend"

// PASS: if-let
fn test(opt: Option[i32]):
    if let Some(x) = opt: print(x)

// PASS: range
fn category(code: i32) -> str:
    match code:
        200 => "ok"; 400..=499 => "client error"; _ => "unknown"

// PASS: slice
fn describe(items: &[i32]) -> str:
    match items:
        [] => "empty"
        [x] => "one"
        [first, ..rest] => "{rest.len()} more"

// FAIL: non-exhaustive nested
fn bad(e: Expr):
    match e:
        Lit(_) => "lit"
        Add(_, _) => "add"       // ERROR: missing Mul
