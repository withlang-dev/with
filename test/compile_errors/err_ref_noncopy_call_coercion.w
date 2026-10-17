//! expect-check-fail: wrong argument type in call to 'take_buffer'

// D120: a struct of values is a value; this one is declared a resource
// so it still moves and still takes no copy.
resource type Buffer { text: str }

fn take_buffer(value: Buffer) -> i64: value.text.len()

fn main:
    let value = Buffer { text: "owned" }
    take_buffer(&value)
