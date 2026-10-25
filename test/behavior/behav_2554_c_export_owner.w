//! check-only
// #2554 helper: a module that defines a C symbol with `@[c_export]`. The
// caller (behav_2554_c_export_extern_caller.w) declares the same name as an
// `extern fn`; the declaration must not drop this definition.
use std.sync

var C2554_TOTAL: AtomicI64 = atomic_new(0)

@[c_export("c2554_bump")]
pub fn c2554_bump(x: i64) -> i64:
    C2554_TOTAL.add(x)
    x * 10

pub fn c2554_total(): atomic_load(&C2554_TOTAL)
