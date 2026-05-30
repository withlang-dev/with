// Spec test: Section 20b — Result is must-use (denied pattern).
// A Result used purely for effect is rejected (see
// test/compile_errors/err_unused_result*.w); these are the accepted forms.

fn fallible(ok: bool) -> Result[i32, str]:
    if ok:
        return Ok(7)
    Err("bad")

// PASS: binding the Result uses it.
fn test_bound:
    let r = fallible(true)
    assert(r.is_ok())

// PASS: explicit discard with `let _`.
fn test_discarded:
    let _ = fallible(false)

// PASS: propagation with `?`.
fn use_propagate() -> Result[i32, str]:
    let v = fallible(true)?
    Ok(v + 1)

fn test_propagate:
    let r = use_propagate()
    assert(r.is_ok())

// PASS: returning the Result as the tail uses it.
fn forward() -> Result[i32, str]:
    fallible(true)

fn test_returned:
    assert(forward().is_ok())
