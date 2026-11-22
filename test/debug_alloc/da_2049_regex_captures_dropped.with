//! expect-debug-alloc: leak count=0
//! expect-stdout: hit
//! expect-stdout: hit again
//! expect-stdout: miss
//! expect-stdout: 2
// #2049: `=~` observes both operands. A named compiled Regex was moved
// into a statement temporary that died with the first condition, so every
// later `=~ re` matched against the reset blank (and never matched); and
// the Option[Captures] the condition tests was never dropped (a leak per
// match). deep-debug-tool-tests validates this program's ownership.
use std.regex

fn main:
    let re = Regex.compile("([a-z])(\\d)").unwrap()
    if "a1 b2" =~ re:
        print("hit")
    if "c3" =~ re:
        print("hit again")
    if "zzz" =~ re:
        print("hit")
    else:
        print("miss")
    print(f"{re.num_captures()}")
