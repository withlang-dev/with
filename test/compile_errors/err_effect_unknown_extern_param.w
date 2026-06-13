//! expect-check-fail: @[effect] names unknown parameter 'q'

@[effect(q: consume)]
extern "C" fn consume_external(p: i32) -> Unit

fn main:
    unsafe { consume_external(1) }
