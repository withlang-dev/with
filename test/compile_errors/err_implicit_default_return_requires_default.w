//! expect-check-fail: return type does not implement Default

type NoDefault { value: i32 }

fn bad -> NoDefault:
    let _x = 1
