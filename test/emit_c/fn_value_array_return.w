//! expect-stdout: 9
//! expect-stdout: 2
//! expect-stdout: 7

// #1817: a fn VALUE whose type returns an array. C returns no arrays, so a
// named function already takes the destination as a leading
// `void* __with_ret` (#1775). One rule reaches every fn-value shape: the fat
// typedef, the thunk that materializes a named function as a value, a
// closure's own signature, and the indirect call site, which passes
// (ctx, dest, args...). The emitter refused all three before.
fn arr() -> [u16; 2]: [7u16, 9u16]
fn call_it(f: fn() -> [u16; 2]) -> [u16; 2]: f()

fn main:
    let f = arr
    let a = f()
    print(f"{a[1]}")
    let g = () => [1u8, 2u8]
    let b = g()
    print(f"{b[1]}")
    let c = call_it(arr)
    print(f"{c[0]}")
