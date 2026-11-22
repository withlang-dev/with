//! expect-stdout: 3 hi!
//! expect-stdout: done
// §18.5b (D74, #1759): a tool-shaped entry source — helper declarations
// beside top-level statements, a `use`, a top-level `let` — checks, builds
// and runs under one rule. The test runner's check and build stages both
// see this file.

use std.fs

fn shout(s: &str) -> str: s ++ "!"

let count = 3
var total = 0
for i in 0..count: total = total + 1
print(f"{total} {shout(\"hi\")}")
print("done")
