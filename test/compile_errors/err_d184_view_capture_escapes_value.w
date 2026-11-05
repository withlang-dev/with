//! expect-error: script helper `first` captures ephemeral binding `view` and is non-escaping

// #2984 (D184, §29.15): a script helper that captures an ephemeral binding
// cannot be referenced as a function value.

let xs = [10, 20]
let view = &xs
fn first(): view[0] + 1
let f = first
print(f())
