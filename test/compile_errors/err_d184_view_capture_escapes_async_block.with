//! expect-error: script helper `mid` captures ephemeral binding `view` and is non-escaping

// #2984 (D184, §29.15): an async block (or escaping closure) cannot spawn a
// call to a script helper that transitively captures an ephemeral binding.

let xs = [10, 20]
let view = &xs
fn leaf() -> isize: view[0]
fn mid() -> isize: leaf()
let t = async:
    mid()
print(t.await)
