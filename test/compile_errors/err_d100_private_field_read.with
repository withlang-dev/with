//! expect-check-fail: field 'Sealed.secret' is private to its package

// D100 (§18.3, #2209): fields follow the same rule as every declaration.
// `secret` has no `pub`, and lib/visibility is another package (it has its
// own with.toml), so reading it from here is refused; `open` is `pub`.
use visibility.private_surface

fn main:
    let s = make_sealed()
    print(f"{s.open} {s.secret}")
