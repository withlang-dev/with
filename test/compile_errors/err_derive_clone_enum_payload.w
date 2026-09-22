//! expect-check-fail: cannot derive Clone for type 'Holder': variant 'Keep' payload of type 'NoClone' does not implement Clone

// #1289: an explicit derive on an enum whose payload cannot supply the
// trait is an error, never an inert attribute.
type NoClone { s: str }
@[derive(Clone)]
enum Holder { Empty | Keep(NoClone) }
fn main:
    print("no")
