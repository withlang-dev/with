//! expect-check-fail: expected 'fn' after 'comptime with' clause

// #490 (§17.1b): the clause binds capabilities into a function.
use std.build
comptime with BuildCtx as ctx:
let x = 1
fn main: ()
