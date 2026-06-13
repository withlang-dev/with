//! expect-check-fail: E0921
//! expect-check-fail: global read here; this global is mutated elsewhere
//! expect-check-fail: program may run concurrently here

global var shared: i32 = 0

async fn marker() -> i32:
    1

fn write_shared:
    unsafe { shared = 1 }

fn read_shared() -> i32:
    shared

fn main:
    write_shared()
    let _ = read_shared()
