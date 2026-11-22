//! expect-check-fail: undefined variable

// #490 (§17.1b): the clause creates no global: the binding is the one function's.
use std.build
comptime with BuildCtx as ctx:
pub fn build -> Build:
    ctx.new_build()

fn other() -> Build:
    ctx.new_build()

fn main: ()
