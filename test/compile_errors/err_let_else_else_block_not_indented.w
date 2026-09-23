//! expect-error: expected an indented block after ':'

// The line after `else:` at the let's own indentation is the next statement,
// not the else branch (§29.13, #1382); taking it as the branch was silent.
fn h(o: Option[i32]) -> i32:
    let Some(v) = o else:
    return v

fn main:
    print(f"{h(Some(1))}")
