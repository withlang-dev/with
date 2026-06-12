//! expect-stdout: ok

use std.alloc

fn main:
    var pool = pool_new(4, 2)
    let a = pool.alloc()
    let b = pool.alloc()
    assert(a as i64 != 0)
    assert(b as i64 != 0)
    assert(a as i64 != b as i64)

    pool.free(a)
    let c = pool.alloc()
    assert(c as i64 == a as i64)

    let d = pool.alloc()
    assert(d as i64 != 0)
    pool.drop()

    var allocator = PoolAllocator.new(8, 1)
    let p0 = allocator.alloc()
    assert(p0 as i64 != 0)
    allocator.free(p0)
    let p1 = allocator.alloc()
    assert(p1 as i64 == p0 as i64)
    allocator.drop()

    print("ok")
