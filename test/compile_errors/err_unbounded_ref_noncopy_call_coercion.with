//! expect-check-fail: wrong argument type in call to 'f'

// D120: a struct of values is a value; this one is declared a resource
// so it still moves and still takes no copy.
resource type Buffer { text: str }

fn take_buffer(value: Buffer) -> Buffer: value
fn forward[T](f: fn(T) -> T, value: &T) -> T: f(value)

fn main:
    let value = Buffer { text: "owned" }
    let _ = forward(take_buffer, &value)
