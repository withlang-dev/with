//! expect-stdout: 3

// §3.8/§5: a function may return a view derived from EITHER of two borrowed
// params on different paths — both reference the caller's live places, so
// either returned view is valid, and the caller's values stay usable for a
// second call. (Formerly spelled with plain by-value params under the
// superseded D5 share-place design; a plain `Buf` param now consumes, so the
// borrowing contract lives in the signature.) Prints 1 + 2 = 3.

type Buf { data: i32 }

fn choose_view(a: &Buf, b: &Buf, take_a: bool) -> &i32:
    if take_a:
        return &a.data
    return &b.data

fn main:
    let a = Buf { data: 1 }
    let b = Buf { data: 2 }
    print_i32(*choose_view(a, b, true) + *choose_view(a, b, false))
