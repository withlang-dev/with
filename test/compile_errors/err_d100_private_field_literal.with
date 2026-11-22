//! expect-check-fail: field 'Sealed.secret' is private to its package

// D100 (§18.3, #2209): naming a private field in a literal reaches it as
// much as reading it does, so another package cannot construct the value.
use visibility.private_surface

fn main:
    let s = Sealed { secret: 5, open: 6 }
    print(f"{s.open}")
