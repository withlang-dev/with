//! expect-stdout: 8 4 u8 1065353216 5

// #2043 (D65): codegen's builtin dispatch switches on the builtin Sema
// recorded for the call (Sema.call_builtins), not on the callee's spelling.
// audit:resolution judges that every builtin call carries that record.
fn main:
    let (tx, rx) = chan[i32](2)
    tx.send(5)
    let bits = unsafe { transmute[u32](1.0 as f32) }
    print(f"{sizeof[i64]()} {alignof[i32]()} {nameof[u8]()} {bits} {rx.recv().unwrap()}")
