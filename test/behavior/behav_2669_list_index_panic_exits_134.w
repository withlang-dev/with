//! expect-exit: 134
//! expect-stderr: List index out of bounds
// #2669: a List operation given an index out of range panics with the panic
// status, 134, as indexing does. The runtime's allocation-free panic path
// (`xs.remove(5)` reaches it) exited 1, so a harness checking for a panic
// saw an ordinary failure, and a fiber could not capture it.
fn main:
    var xs: List[i32] = List.new()
    xs.push(1)
    let _ = xs.remove(5)
