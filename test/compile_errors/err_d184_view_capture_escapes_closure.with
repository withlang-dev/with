//! expect-error: script helper `first` captures ephemeral binding `view` and is non-escaping

// #2984 (D184, §29.15): an escaping closure (such as `spawn_os`) cannot call a
// script helper that captures an ephemeral binding.

use std.thread

let xs = [10, 20]
let view = &xs
fn first() -> isize: view[0]
let h = spawn_os(() => print(first()))
print("spawned")
