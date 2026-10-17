//! expect-check-fail: use of moved value
// D120: a struct of values is a value; this one is declared a resource
// so it still moves and still takes no copy.
resource type Counter { value: i32 }

impl Counter:
    fn into_value(move self: Self) -> i32:
        self.value

fn main:
    let c = Counter { value: 42 }
    let _ = c.into_value()
    let _ = c.into_value()   // error: c was moved
