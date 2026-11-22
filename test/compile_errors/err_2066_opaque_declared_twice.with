//! expect-check-fail: type `Handle` is declared twice in this module

// #2066 (found by #2043): the shape c_import emitted for
// `typedef struct Handle Handle;` — one opaque type declared twice, with an
// alias between them that named the first while `Handle` named the second.

type Handle = opaque
type struct_Handle = Handle
type Handle = opaque

fn main:
    print("unreachable")
