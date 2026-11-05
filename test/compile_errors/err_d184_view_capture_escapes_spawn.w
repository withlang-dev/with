//! expect-error: script helper `first` captures ephemeral binding `view` and is non-escaping

// #2984 (D184, §29.15): an async script helper that captures an ephemeral
// binding cannot be spawned as a task.

let xs = [10, 20]
let view = &xs
async fn first() -> isize: view[0]
let t = first()
print(t.await)
