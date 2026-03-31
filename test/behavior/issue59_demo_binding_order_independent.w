//! expect-stdout: ok

use demo.core
use demo.device
use demo.memory
use demo.program
use demo.stream
use demo.view

fn write_i32(mem: Memory, index: i32, value: i32):
    let ptr = memory_ptr(mem) as *mut i32
    unsafe:
        *(ptr + index as i64) = value

fn read_i32(mem: Memory, index: i32) -> i32:
    let ptr = memory_ptr(mem) as *mut i32
    unsafe: *(ptr + index as i64)

fn main:
    let n = 3usize
    let bytes = n * 4usize
    let a_mem = alloc(default_device(), bytes).unwrap()
    let out_mem = alloc(default_device(), bytes).unwrap()
    write_i32(a_mem, 0, -2)
    write_i32(a_mem, 1, 4)
    write_i32(a_mem, 2, -1)
    var src = program_source("main")
    src.ir_text = "param a in [N] i32\nparam out out [N] i32\n%0 = const i32 0\n%1 = const i32 3\n%2 = const i32 0\nparallel 0 %0 %1 1\nblock_begin 1\n%5 = load a [@0]\n%6 = lt %5 %2\n%7 = select %6 %2 %5\nstore out [@0] %7\nblock_end 1\nreturn\n"
    let prog = compile(default_device(), src).unwrap()
    let entries: Vec[BindEntry] = Vec.new()
    entries.push(bind("out", view_contiguous(out_mem, shape1(n), .Int32)))
    entries.push(bind("a", view_contiguous(a_mem, shape1(n), .Int32)))
    let stream = stream_create(default_device())
    let event = dispatch(stream, prog, bindings_from(entries)).unwrap()
    assert(event_is_done(event))
    assert(read_i32(out_mem, 0) == 0)
    assert(read_i32(out_mem, 1) == 4)
    assert(read_i32(out_mem, 2) == 0)
    event_destroy(event)
    stream_destroy(stream)
    program_destroy(prog)
    free(a_mem)
    free(out_mem)
    print("ok")
