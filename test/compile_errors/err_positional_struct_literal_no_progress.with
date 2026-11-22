//! expect-error: expected a field value in a positional struct literal

// A positional struct literal whose later field is `name: value` is
// reported, not spun on: the parser once looped forever on a field it
// could not parse and never consumed (found by #1746: `{ it, left: n }`,
// where `it` is a keyword, took the positional form).

type Taken { inner: i32, left: i64 }

fn mk(it: i32, n: i64) -> Taken: Taken { it, left: n }

type Dropped { inner: i32, pending: i64 }

fn main:
    let t = mk(1, 2)
    print(t.left)
