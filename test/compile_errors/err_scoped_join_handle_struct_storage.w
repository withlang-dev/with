//! expect-check-fail: ephemeral type 'ScopedJoinHandle' cannot be stored in non-ephemeral struct

type Holder {
    handle: ScopedJoinHandle,
}

fn main:
    0
