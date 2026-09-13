//! expect-stdout: ok

fn make_identity[T: Copy](sample: &T):
    let outer: fn(T) -> T = value => {
        let inner: fn(T) -> T = item => item
        inner(value)
    }
    outer

fn async_identity[T: Copy](value: T):
    let task = async:
        let identity: fn(T) -> T = item => item
        identity(value)
    task.await

fn main:
    let narrow = 37
    let wide: i64 = 1099511627776
    let narrow_identity = make_identity(narrow)
    let wide_identity = make_identity(wide)
    assert(narrow_identity(narrow) == narrow)
    assert(wide_identity(wide) == wide)
    assert(async_identity(narrow) == narrow)
    assert(async_identity(wide) == wide)
    print("ok")
