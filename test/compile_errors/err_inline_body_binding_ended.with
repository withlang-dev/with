//! expect-error: an inline `:` body is one statement, and a `;` ends it as a newline does (§29.13)

// A `;` ends an inline `:` body as a newline would (§29.13), so `f` lives
// only in the `if`. The error said "did you mean 'c'?"; it now says where
// `f` was bound and that braces keep both statements in the body.

fn main:
    let c = true
    if c: let f = 3; print(f)
