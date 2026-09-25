//! expect-check-fail: cannot infer return type: if arms have types i32 and str
pub fn exported_mixed(b: bool):
    if b: 1
    else: "one"

fn main:
    exported_mixed(true)
