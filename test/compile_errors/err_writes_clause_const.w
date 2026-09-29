//! expect-check-fail: `writes LIMIT`: `LIMIT` is a const, a value and not a place (§9.1c)

// §21.1 rule 1 (Eric 2026-09-29): a const is a value, not a place (§9.1c):
// no body writes it, so a `writes` clause naming one is refused.
const LIMIT: i32 = 4

fn limit() -> i32 writes LIMIT: LIMIT

fn main:
    print(limit())
