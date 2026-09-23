//! expect-check-fail: ephemeral type 'CStr' cannot be stored in non-ephemeral struct

// D51 §41 / spec §16.2b.8, §5: a `CStr` is a view of NUL-terminated bytes
// something else owns — never the owner — so it is ephemeral: it cannot be
// stored past the origin it was borrowed from. An owned copy is spelled
// `to_owned()`; an owned C string is a `CString`.
type Holder { text: CStr }

fn main:
    let h = Holder { text: unsafe { CStr.from_ptr(c"x".ptr) } }
    print(f"{h.text.len()}")
