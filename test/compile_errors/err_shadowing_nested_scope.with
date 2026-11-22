//! expect-check-fail: shadowing is not allowed for 'x'
// §29.8: a nested block may not shadow a name still visible from an outer scope.
fn main:
    let x = 1
    if true:
        let x = 2
        let _ = x
    let _ = x
