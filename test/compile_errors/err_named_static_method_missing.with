//! expect-error: missing argument for parameter 'required'
type Settings {}
fn Settings.open(required: i32, optional: i32 = 0) -> i32: required + optional
fn main:
    Settings.open(optional: 1)
