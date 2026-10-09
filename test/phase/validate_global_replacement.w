//! args: --validate-all --prelude=core
//! expect-check-stdout: validate-all: ok

use std.collections

var values: List[str] = List.new()

fn clear(): values = List.new()

fn main:
    values.push("owned")
    clear()
