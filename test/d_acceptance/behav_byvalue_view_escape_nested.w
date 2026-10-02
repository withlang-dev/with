//! expect-stdout: 7

// §D5 share-place: a view into a NESTED field of a by-value param is valid — the
// origin is the caller's live place. Previously rejected; share-place makes it
// correct.

use std.builtins.print_i32
type Inner { data: i32 }
type Buf { inner: Inner }

fn nested_view(b: Buf) -> &i32: &b.inner.data

fn main:
    let b = Buf { inner: Inner { data: 7 } }
    let v = nested_view(b)
    print_i32(*v)
