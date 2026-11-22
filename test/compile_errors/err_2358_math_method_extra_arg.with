//! expect-error: `sqrt` expects 0 argument(s), found 1

// #2358: the free form `sqrt(x, y)` was already refused ("sqrt() expects
// one argument"); the method form silently ignored the extra operand. The
// receiver is sqrt's one operand, so the method takes no arguments.

fn main:
    let x: f64 = 9.0
    print(x.sqrt(2.0))
