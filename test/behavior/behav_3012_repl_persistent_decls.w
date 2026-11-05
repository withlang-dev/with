//! expect-stdout: 10
//! expect-stdout: 42
//! expect-stdout: ok

// #3012 (§18.5): pins the script-session structure `with repl` accumulates
// across inputs (`cli-selfhost-edge-tests` runs the interactive `with repl`
// subprocess end-to-end across `use`, `type`, `fn`, `var`, mutation, and
// multi-turn `print`).

use std.string.parse

type Boxed { v: i32 }
fn add_box(b: Boxed, d: i32): b.v + d

var n: i32 = parse("10").unwrap()
print(n)
n = add_box(Boxed { v: n }, 32)
print(n)
print("ok")
