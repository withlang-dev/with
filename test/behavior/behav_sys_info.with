//! expect-stdout: ok

use std.sys

fn main:
    let cores = cpu_count()
    let mem = total_memory()
    let ps = page_size()
    let bw = memory_bandwidth()

    assert(cores >= 1)
    assert(mem > 0usize)
    assert(ps >= 4096usize)
    assert(bw > 0.0)

    // Verify caching: second call should return same values
    assert(cpu_count() == cores)
    assert(total_memory() == mem)
    assert(page_size() == ps)
    assert(memory_bandwidth() == bw)

    print("ok")
