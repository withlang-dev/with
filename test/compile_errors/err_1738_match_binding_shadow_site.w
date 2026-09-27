//! expect-error: shadowing is not allowed for 'v'
//! expect-check-fail-not: err_1738_match_binding_shadow_site.w:1:1
// #1738: a match-arm binding that shadows a local is reported at the
// pattern, not at 1:1 of the file (the pattern binding reached the scope
// without its node).

fn f() -> Result[i32, str]:
    Ok(1)

fn main:
    let v = 3
    match f():
        Ok(v) => print(f"{v}")
        Err(e) => print(e)
