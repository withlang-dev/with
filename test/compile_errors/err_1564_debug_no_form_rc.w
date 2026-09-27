//! expect-check-fail: cannot format a value of type 'fn(i32) -> i32' with :? — §15.4.7 gives it no Debug form

// D71 / §15.4.7 (#1564): an `Rc[T]` formats the value it holds, so an Rc of
// a value with no Debug form has none either. It printed its handle,
// `Rc { ptr: 4344693328 }`, whatever it held.

use std.rc.Rc

fn twice(x: i32): x * 2

fn main:
    let op = Rc.new(twice)
    print(f"{op:?}")
