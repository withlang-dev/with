//! expect-check-fail: write the return type

// D141: a branch already of type Option[T] beside None does not join into
// an inferred return — Option[Option[T]] would be a second meaning — so the
// type is written.
fn pick(n: i32, o: Option[i32]):
    if n < 0: return None
    o

fn main:
    print(f"{pick(1, Some(2)).is_some()}")
