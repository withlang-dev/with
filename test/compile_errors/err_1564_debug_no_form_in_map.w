//! expect-check-fail: cannot format a value of type 'fn(i32) -> i32' with :? — §15.4.7 gives it no Debug form
//! expect-check-fail-not: <embedded-std>

// D71 / §15.4.7 (#1564): a value with no Debug form is a compile error
// "under `:?`" — the program's `:?`. A map's form is a std method whose body
// formats each value with its own `{v:?}`, and the error was reported there
// (`<embedded-std>/std/collections.w`), naming a line the program never
// wrote; it is reported at the `:?` that reached the map.

use std.collections

fn twice(x: i32): x * 2

fn main:
    var ops: HashMap[str, fn(i32) -> i32] = HashMap.new()
    ops.insert("twice", twice)
    print(f"{ops:?}")
