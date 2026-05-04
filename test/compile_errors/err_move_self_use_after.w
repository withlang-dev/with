//! expect-check-fail: use of moved value
type Counter { value: i32 }

impl Counter:
    fn into_value(move self: Self) -> i32:
        self.value

fn main:
    let c = Counter { value: 42 }
    let _ = c.into_value()
    let _ = c.into_value()   // error: c was moved
