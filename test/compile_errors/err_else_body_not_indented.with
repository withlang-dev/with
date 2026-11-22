//! expect-error: expected an indented block after ':'

// #1391 (§29.13 Form 2): an `else:` body sits deeper than the `else`.
fn h(c: bool) -> i32:
    if c:
        return 1
    else:
    return 2

fn main:
    print(f"{h(true)}")
