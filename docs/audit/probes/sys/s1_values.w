use std.sys
use std.builtins.print_i64

fn main:
    print_i32(cpu_count())
    print_i64(total_memory() as i64)
    print_i64(page_size() as i64)
    assert(memory_bandwidth() > 0.0)
    print("ok")
