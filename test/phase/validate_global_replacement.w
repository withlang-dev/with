//! args: --validate-all --prelude=core
//! expect-check-stdout: validate-all: ok

use std.collections

var values: Vec[str] = Vec.new()

fn clear(): values = Vec.new()

fn main:
    values.push("owned")
    clear()
