//! expect-check-fail: duplicate capability binding in comptime with clause

// #490 (§17.1b): two capabilities whose default binding is the same name need explicit 'as' bindings.
use std.build
comptime with BuildCtx, ActionCtx:
fn f() -> i32: 0
fn main: ()
