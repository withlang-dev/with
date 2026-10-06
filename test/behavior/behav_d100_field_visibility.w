//! expect-stdout: 2
//! expect-stdout: 7 8

// D100 (§18.3, #2209): a `pub` field of another package's type reads from
// here (lib/visibility/fields.w is this program's own module, so its
// private fields read too: one package). err_d100_private_field_read is
// the refusal across a package boundary.
use visibility.fields

fn main:
    let g = make_gate()
    print(f"{g.open}")
    let h = Hidden { inner: 7, open: 8 }
    print(f"{h.inner} {h.open}")
