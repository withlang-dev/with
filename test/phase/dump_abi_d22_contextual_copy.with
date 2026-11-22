//! args: --dump-abi
//! expect-check-stdout: fn take_owned
//! expect-check-stdout: param[0] ty=3 eff=[read] value_ref_abi=0 -> COPY

// Contextual Copy is a source adjustment at the selected call. It must not
// change the already-established i32 parameter/result ABI.
fn take_owned(value: i32) -> i32: value

fn main:
    let source = 17
    let view = &source
    let copied = take_owned(view)
    assert(copied == 17)
