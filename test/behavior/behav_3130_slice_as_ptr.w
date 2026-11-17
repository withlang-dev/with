//! expect-stdout: 104 121 true
//! expect-stdout: 20 30 true
//! expect-stdout: 7 9
//! expect-stdout: 104

// #3130: a slice's data pointer is `as_ptr()` (`as_mut_ptr()` for a
// `[]mut`), named as List's is. Making the pointer is safe; reading
// through it is `unsafe`. A view of a str, of a list's middle, a `[]mut`
// written through, and a slice held through a reference.
fn first(v: &[]u8) -> u8:
    let p = v.as_ptr()
    unsafe { *p }

fn bump(v: []mut i32):
    let p = v.as_mut_ptr()
    unsafe { *p = *p + 6 }

fn main:
    let text = "hey"
    let bytes = text.as_bytes()
    let p = bytes.as_ptr()
    print(f"{unsafe { *p }} {unsafe { p[2] }} {p == &raw const bytes[0]}")
    let xs: List[u8] = [10, 20, 30, 40]
    let mid = xs[1..3]
    let q = mid.as_ptr()
    print(f"{unsafe { *q }} {unsafe { q[1] }} {q == &raw const xs[1]}")
    var ns: List[i32] = [1, 9]
    bump(ns)
    print(f"{ns[0]} {ns[1]}")
    print(first(bytes))
