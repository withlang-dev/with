//! expect-error: expected ':' after 'else': a let-else branch on the next line is a body

// D58 (§9.7, §29.13): a bare `else` takes a single diverging expression on
// the same line; a branch on the next line is a body and needs `else:`.
fn h(o: Option[i32]) -> i32:
    let Some(v) = o else
        return -1
    v

fn main:
    print(f"{h(Some(1))}")
