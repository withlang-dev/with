//! expect-check-fail: ephemeral values cannot be stored in non-ephemeral structs

type Holder {
    task: ScopedTask[i32],
}

fn main:
    0
