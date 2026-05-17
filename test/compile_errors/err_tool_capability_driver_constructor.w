//! expect-error: tool capability constructor 'BuildCtx.__driver_new' can only be called by the compiler driver

use std.build

fn main:
    let pkg = Package { name: "app", version: "0.1.0" }
    let _ctx = BuildCtx.__driver_new(pkg, ".", "fake")
