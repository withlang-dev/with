//! expect-error: tool capability constructor 'SourceEmitter.__driver_new' can only be called by the compiler driver

use std.compiler

fn main:
    let _source = SourceEmitter.__driver_new("fake", "out.w")
