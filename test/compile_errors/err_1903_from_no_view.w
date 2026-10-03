//! expect-error: `twice` returns no view: a `from` clause names the origins of a returned view (§21.1 rule 6)

// #1903 (§21.1 rule 6): `from` states a returned view's origins; an owned
// result has none.

fn twice(x: i32) -> i32 from x: x * 2

fn main:
    print(twice(2))
