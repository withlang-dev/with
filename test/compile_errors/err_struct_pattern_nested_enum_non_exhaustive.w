//! expect-check-fail: non-exhaustive match on 'W': `W { o: None, .. }` is not covered

// #1388 (§9.7): a variant pattern in a field covers only that variant.

type W { o: Option[i32], n: i32 }

fn f(w: W) -> i32:
    match w:
        W { o: Some(_), n } => n

fn main:
    print(f(W { o: None, n: 2 }))
