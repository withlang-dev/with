//! expect-check-fail: comparison operator method must return bool

type Marker { value: i32 }

impl Marker:
    fn eq(self: &Self, rhs: &Self) -> i32:
        self.value - rhs.value

fn main:
    let _ = Marker { value: 1 } == Marker { value: 1 }
