//! expect-stdout: 1

// §D5 share-place: a by-value non-Copy param is an IndirectPlace (a pointer to
// the caller's place), so returning a view derived from it is VALID — the view
// points into the caller's live binding and view-origin tracking keeps it safe.
// Previously rejected as an escape; share-place makes it correct.

use std.builtins.print_i32
type Buf { data: i32 }

fn first_view(b: Buf) -> &i32: &b.data

fn main:
    let b = Buf { data: 1 }
    let v = first_view(b)
    print_i32(*v)
