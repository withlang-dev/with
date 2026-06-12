//! expect-error: E0702

async fn borrow_value(value: &i32) -> i32:
    *value

fn main:
    let value = 42
    no_suspend:
        let task = borrow_value(&value)
        task.cancel()
        assert(value == 42)
