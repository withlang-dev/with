//! expect-error: cannot iterate over `str`: a `for` iterable implements `Iter[T]`

// #1828 (§13.5): a `str` is not iterable — it implements no Iter[T] and has
// no `.iter()`. The loop bound its variable as `i32`, passed check and
// failed MIR lowering.
let G = "abc"

fn main:
    for r in G:
        print(f"{r}")
