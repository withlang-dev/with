//! args: --validate-all --prelude=core
//! expect-check-stdout: validate-all: ok

use std.collections

fn empty():
    var values: List[str]

fn main: empty()
