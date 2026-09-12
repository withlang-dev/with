//! args: --validate-all --prelude=core
//! expect-check-stdout: validate-all: ok

use std.collections

fn empty():
    var values: Vec[str]

fn main: empty()
