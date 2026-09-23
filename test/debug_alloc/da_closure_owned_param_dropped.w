//! expect-debug-alloc: leak count=0
//! expect-stdout: 1
//! expect-stdout: 7
//! expect-stdout: kept!
//! expect-stdout: 0

// #1363: a closure's plain `T` parameter consumes (§3.8, D5) — every call
// site moves the argument in and blanks its source without dropping it — but
// the anonymous body never scheduled a drop for its parameters, so an owned
// argument the body did not move on leaked. unwrap_or_else's fallback
// receives the Err payload that way: `(_) => ""` leaked the IoError once the
// subject's own drop stopped freeing the payload behind the result's back.
use std.fs
use std.process

fn main:
    let unused = (x: str) => 1
    print(unused(args()[0].clone() ++ "?"))
    let reads = (x: str) => x.len() as i32 * 0 + 7
    print(reads(args()[0].clone() ++ "!"))
    let keeps = (x: str) => x
    print(keeps("kept" ++ "!"))
    let t = read_file("out/tmp/da_closure_owned_param_dropped.missing").unwrap_or_else((_) => "")
    print(t.len())
