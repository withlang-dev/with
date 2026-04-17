//! expect-check-fail: expected identifier
// Any non-identifier at a field position (here `123`) must surface
// a diagnostic instead of looping forever. See
// err_struct_lit_nested_needs_colon.w for the root cause.
fn main:
    let g = Foo { 123 }
