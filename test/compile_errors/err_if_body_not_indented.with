//! expect-error: expected an indented block after ':'

// #1391 (§29.13 Form 2): the line after `if c:` at the `if`'s own column is
// the next statement, not the body. It used to be taken as the body, and the
// errors were about the consequences (unreachable code, missing else,
// missing return) instead of the missing indent.
fn h(c: bool) -> i32:
    if c:
    return 1
    2

fn main:
    print(f"{h(true)}")
