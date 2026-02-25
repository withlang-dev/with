// Test: std.mem import
use std.mem

fn main() -> i32 =
    // Allocate some memory
    let ptr = alloc(100)
    assert(ptr != 0)

    // Zero it out
    mem_set(ptr, 0, 100)

    // Free it
    free_mem(ptr)

    // Alloc zeroed
    let zptr = alloc_zeroed(10, 8)
    assert(zptr != 0)
    free_mem(zptr)

    println("all stdlib mem tests passed")
    0
