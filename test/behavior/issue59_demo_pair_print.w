//! expect-stdout: sum=10
//! expect-stdout: relu=0,0,0,2,5

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
    unsafe *(ptr + index as i64)

fn main:
    let count: i32 = 4
    let n = count as Size
    let a_mem = alloc(default_device(), n * 4usize).unwrap()
    let out_mem = alloc(default_device(), 4usize).unwrap()
    write_i32(a_mem, 0, 1)
    write_i32(a_mem, 1, 2)
    write_i32(a_mem, 2, 3)
    write_i32(a_mem, 3, 4)
    write_i32(out_mem, 0, 0)
    var src = program_source("main")
    src.ir_text = "param a in [N] i32\nparam out inout [] i32\n%0 = const i32 0\n%1 = const i32 4\nloop 0 %0 %1 1\nblock_begin 1\n%4 = load out []\n%5 = load a [@0]\n%6 = add %4 %5\nstore out [] %6\nblock_end 1\nreturn\n"
    let prog = compile(default_device(), src).unwrap()
    let entries: Vec[BindEntry] = Vec.new()
    entries.push(bind("a", view_contiguous(a_mem, shape1(n), .Int32)))
    entries.push(bind("out", view_contiguous(out_mem, shape_scalar(), .Int32)))
    let stream = stream_create(default_device())
    let event = dispatch(stream, prog, bindings_from(entries)).unwrap()
    assert(event_is_done(event))
    print(f"sum={read_i32(out_mem, 0)}")
    event_destroy(event)
    stream_destroy(stream)
    program_destroy(prog)
    free(a_mem)
    free(out_mem)

    let count2: i32 = 5
    let n2 = count2 as Size
    let bytes2 = n2 * 4usize
    let a2 = alloc(default_device(), bytes2).unwrap()
    let out2 = alloc(default_device(), bytes2).unwrap()
    write_i32(a2, 0, -3)
    write_i32(a2, 1, -1)
    write_i32(a2, 2, 0)
    write_i32(a2, 3, 2)
    write_i32(a2, 4, 5)
    var src2 = program_source("main")
    src2.ir_text = "param a in [N] i32\nparam out out [N] i32\n%0 = const i32 0\n%1 = const i32 5\n%2 = const i32 0\nparallel 0 %0 %1 1\nblock_begin 1\n%5 = load a [@0]\n%6 = lt %5 %2\n%7 = select %6 %2 %5\nstore out [@0] %7\nblock_end 1\nreturn\n"
    let prog2 = compile(default_device(), src2).unwrap()
    let entries2: Vec[BindEntry] = Vec.new()
    entries2.push(bind("a", view_contiguous(a2, shape1(n2), .Int32)))
    entries2.push(bind("out", view_contiguous(out2, shape1(n2), .Int32)))
    let stream2 = stream_create(default_device())
    let event2 = dispatch(stream2, prog2, bindings_from(entries2)).unwrap()
    assert(event_is_done(event2))
    print(f"relu={read_i32(out2, 0)},{read_i32(out2, 1)},{read_i32(out2, 2)},{read_i32(out2, 3)},{read_i32(out2, 4)}")
    event_destroy(event2)
    stream_destroy(stream2)
    program_destroy(prog2)
    free(a2)
    free(out2)
