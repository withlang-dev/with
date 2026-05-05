//! expect-check-fail: 'copy' requires the type to implement Copy or Clone

type Lock { id: i32 }
impl Lock:
    fn drop(move self: Self): ()
// Lock has no Copy and no Clone impl

fn use_lock(l: Lock) -> i32:
    return l.id

fn main:
    let l = Lock { id: 1 }
    let _ = use_lock(copy l)   // error: Lock implements neither Copy nor Clone
