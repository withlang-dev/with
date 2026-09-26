//! expect-stdout: a!
//! expect-stdout: a!

// #1603 (§3.7): a call through a `&fn(A) -> R` parameter dereferences the
// reference like any other `&T` use; `&shout` is a reference to the
// callable, not the code address.
fn apply(s: &str, read: &fn(&str) -> str) -> str: read(s)
fn shout(s: &str) -> str: s.clone() ++ "!"
fn main:
    var i = 0
    while i < 2:
        print(apply("a", &shout))
        i = i + 1
