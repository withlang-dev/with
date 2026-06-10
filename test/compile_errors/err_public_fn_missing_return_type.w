//! expect-check-fail: public function declarations require an explicit return type

pub fn exported:
    1

fn main:
    let _ = exported()
