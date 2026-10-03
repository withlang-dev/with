//! expect-check-fail: call to `set` mutates global `CONFIG` while `d` is a live view into it

// #1903 (§21.1 rule 6): the accessor `peek` stays legal — its returned view
// has the origin CONFIG, so a write of CONFIG while that view is live is
// refused, as for `let d = &CONFIG`.

type Config { limit: i32 }

var CONFIG = Config { limit: 1 }

fn peek() -> &Config: &CONFIG

fn set(n: i32): CONFIG = Config { limit: n }

fn main:
    let d = peek()
    set(6)
    print(d.limit)
