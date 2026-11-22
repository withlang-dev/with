//! expect-check-fail: wrong argument count
//! expect-check-fail-not: unknown type

// #1336: the arity error is the only diagnostic. The unit-elision check for
// a zero-argument call resolved `val: T` without the callee's own type
// parameters bound and led with `unknown type 'T'` at the declaration.

fn id[T](val: T) -> T: val

fn main:
    let x = id()
