//! expect-check-fail: return type mismatch

// §9.1 / §4.10 / D60: `Result[Unit, E]` is not `Unit`, so the tail
// assignment is the body's value — a read of `self.n`, an i32. §4.9 wraps a
// tail of type `Unit` in `Ok`; an i32 matches neither the Ok type nor the
// Result, so this is a type error, not an implicit `Ok(())` (#1296 under
// #1319 discarded the value).

error E = Bad
type P { n: i32 = 0 }
extend P:
    mut fn bump() -> Result[Unit, E]:
        self.n += 1

fn main:
    var p = P { }
    p.bump()
