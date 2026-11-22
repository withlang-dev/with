//! expect-stdout: Some(x) => x
//! expect-stdout: true
//! expect-stdout: 5
// #2525: a regex literal may begin with `=`. Where a regex can start (after
// `=`, `(`, `,`, a keyword) `/=` has no left operand to divide, so it is
// not the compound assignment; `x /= 2` still is.
use std.regex

fn main:
    let line = "Some(x) => Some(x)"
    print(/=> Some\((.*)\)\s*$/.replace(line, "=> $1"))
    print(line =~ /=> /)
    var n = 10
    n /= 2
    print(n)
