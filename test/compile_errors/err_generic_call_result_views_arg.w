//! expect-error: cannot mutate `v` while `w` is a live view into it

// §21.1: a generic function's returned view is tied to its argument at the
// call exactly as a monomorphic function's is. The generic free-call path
// (check_generic_call) resolved the specialization but never recorded the
// call's view origins, so `first(&v)` left `w` unattached and `v.push`
// went unchecked (the seed accepts this program).
fn first[T](v: &List[T]) -> &T: v[0]

fn main:
    var v: List[i64] = [4, 5, 6]
    let w = first(&v)
    v.push(7)
    print(*w)
