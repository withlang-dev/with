//! expect-build-fail: unhandled MirIntrinsic.MIR_INTRINSIC_GENERIC_CALL

fn get_len[T](x: T) -> i32:
    x.len()

fn main:
    let n = get_len(42)
