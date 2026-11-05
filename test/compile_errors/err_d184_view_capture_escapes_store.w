//! expect-error: script helper `first` captures ephemeral binding `view` and is non-escaping

// #2984 (D184, §29.15): a script helper that captures an ephemeral binding
// cannot be stored in a record or collection, regardless of declaration order.

type Holder { f: fn() -> isize }

let xs = [10, 20]
let view = &xs
let h = Holder { f: first }
print((h.f)())

fn first() -> isize: view[0]
