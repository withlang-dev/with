//! expect-check-fail: cannot infer type parameter 'T'

// §4.9a (D103): the conversion does not participate in inference. It fires
// only once the demanded type is known, so `first(3)` against
// `Option[T]` never solves `T := i32`; the parameter is uninferable.
fn first[T](x: Option[T]) -> bool: x.is_some()

fn main:
    print(first(3))
