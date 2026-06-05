//! expect-stdout: ok

type CallbackHolder {
    cb: extern "C" fn(value: i32) -> i32,
}

fn add_one(value: i32) -> i32:
    value + 1

fn apply_raw(cb: extern "C" fn(i32) -> i32, value: i32) -> i32:
    cb(value)

fn main:
    let from_name: extern "C" fn(value: i32) -> i32 = add_one
    assert(from_name(41) == 42)

    let from_closure: extern "C" fn(i32) -> i32 = value => value * 2
    assert(from_closure(21) == 42)

    let holder = CallbackHolder { cb: value => value - 1 }
    assert(holder.cb(43) == 42)
    assert(apply_raw(value => value + 2, 40) == 42)

    print("ok")
