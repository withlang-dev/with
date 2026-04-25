//! skip
// Spec test: Section 4.4 — Enum Accessor Methods (formerly 25.52)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: .is_variant() on data variants
enum Token { TInt(i64) | TStr(str) | TBool(bool) | TNull }
fn test:
    let t = Token.TInt(42)
    assert(t.is_tint())
    assert(!t.is_tstr())
    assert(!t.is_tnull())

// PASS: .as_variant() returns Option
fn test:
    let t = Token.TStr("hello")
    assert(t.as_tstr() == Some("hello"))
    assert(t.as_tint() == None)

// PASS: chaining with ?? and optional chaining
fn test:
    let t = Token.TInt(42)
    let n = t.as_tint() ?? 0
    assert(n == 42)

// PASS: multi-field variant returns tuple
enum Shape { Circle(f64) | Rect(f64, f64) }
fn test:
    let s = Shape.Rect(3.0, 4.0)
    let (w, h) = s.as_rect() ?? unreachable()
    assert(w == 3.0)
    assert(h == 4.0)

// PASS: unit variants only get .is_variant()
enum Color { Red | Green | Blue }
fn test:
    let c = Color.Red
    assert(c.is_red())
    assert(!c.is_green())

// PASS: works with enum variant shorthand
enum Result2 { Success(i32) | Failure(str) }
fn test:
    let r: Result2 = .Success(10)
    assert(r.as_success() == Some(10))
    assert(r.as_failure() == None)
