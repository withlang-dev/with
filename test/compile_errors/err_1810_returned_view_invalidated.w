//! expect-error: cannot mutate `s` while `t` is a live view into it

// #1810: a view returned from `tail` keeps its argument's origin (§21.1
// Rule 6), so assigning the viewed string while the view lives is refused
// exactly as it is for the string itself.
fn tail(s: &str) -> &str: s[1..]

fn main:
    var s = "abc"
    let t = tail(s)
    s = "xyz"
    print(t)
