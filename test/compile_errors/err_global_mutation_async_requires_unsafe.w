//! expect-check-fail: E0921
//! expect-check-fail: global mutated here
//! expect-check-fail: program may run concurrently here

global var counter: i32 = 0

async fn worker() -> i32:
    1

fn bump:
    counter = counter + 1

fn main:
    bump()
