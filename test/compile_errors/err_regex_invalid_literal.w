//! skip-windows: issue #798: regex-literal comptime validation crashes (0xC0000005) on native Windows
//! expect-check-fail: invalid regex literal

fn main:
    let _ = /(/
