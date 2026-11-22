//! expect-check-fail: unknown method 'unwrap' for type 'Msg'

// #672: the raw-encoded-optional catch-all (HashMap.get legacy) must not
// accept `.unwrap()` on a plain enum — codegen would extract a phantom
// Option payload from it and corrupt the value.

enum Msg:
    Ping(i32)
    Stop

fn main:
    let m = Ping(3)
    let _ = m.unwrap()
