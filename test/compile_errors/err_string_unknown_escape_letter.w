//! expect-error: unknown escape sequence '\q' in string literal

// #929: unknown escapes silently dropped the backslash (`\q` -> `q`).
fn main:
    print("a\qb")
