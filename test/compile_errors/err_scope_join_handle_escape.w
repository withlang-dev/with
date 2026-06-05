//! expect-check-fail: scope result cannot be ephemeral

fn main:
    let handle = scope s =>:
        let spawned = s.spawn(() => 1)
        spawned
    let _ = handle.join()
