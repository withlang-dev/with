//! expect-error: missing argument for parameter 'required'
fn open(required: i32, optional: i32 = 0) -> i32: required + optional
fn main:
    open(optional: 1)
