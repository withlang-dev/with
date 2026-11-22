//! expect-error: unknown escape sequence '\q' in string literal

// #929 companion: C-string literals go through the same escape validation
// as plain strings — an unknown escape must never silently drop its backslash.
fn main:
    let p = c"a\qb"
