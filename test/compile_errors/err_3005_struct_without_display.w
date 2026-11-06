//! expect-check-fail: no default display

// #3005 (§15.4.8): a struct with no `impl Display` has no default display;
// `{p}` is refused, `{p:?}` is the Debug form.
type Plain { n: i32 }
fn main:
    let p = Plain { n: 1 }
    print(f"{p}")
