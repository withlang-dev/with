//! expect-error: expected an indented block after ':'

// §29.13: a colon ending the line with no indented block is a syntax error (#1382).
fn h(o: Option[i32]) -> i32:
    let Some(v) = o else:
fn main:
    print(f"{h(Some(1))}")
