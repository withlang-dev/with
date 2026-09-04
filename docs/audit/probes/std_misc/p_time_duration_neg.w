// NEGATIVE probe: documents T10 finding — Duration is private in std/time.w.
// Expected: check FAILS with "symbol 'Duration' is private".
use std.time

fn main():
    let d = Duration.seconds(2)
    print(f"{d}\n")
