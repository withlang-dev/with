//! expect-check-fail: duplicate capability binding in comptime with clause

// #490 (§17.1b): one binding name is used once in a clause.
use std.build
comptime with ToolFs as x, ProcessRunner as x:
fn f() -> i32: 0
fn main: ()
