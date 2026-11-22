//! expect-check-fail: a `pub` binding of an empty literal states its type (§4.3c)
// #3194: a `pub` binding's type is part of the module's interface; a body
// edit must not change it, so its uses never decide it.
pub var xs = []

fn a(): xs.push(1)

fn main:
    a()
