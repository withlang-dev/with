//! expect-error: parameter 'value' specified more than once
type Settings {}
fn Settings.open(value: i32 = 0) -> i32: value
fn main:
    Settings.open(1, value: 2)
