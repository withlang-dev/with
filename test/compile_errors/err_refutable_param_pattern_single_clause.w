//! expect-error: refutable parameter pattern requires another function clause or an else

fn only(Some(x): Option[i32]) -> i32:
    x

fn main:
    assert(only(Some(1)) == 1)
