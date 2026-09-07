use std.zlib
use std.zlib.gzlib
use std.zlib.gzwrite
use std.zlib.gzclose
use std.libc

unsafe fn run():
    let payload: Vec[u8] = Vec.new()
    var i: i64 = 0
    while i < 3000:
        payload.push(65 as u8)
        payload.push(66 as u8)
        i = i + 1
    let comp = compress_level(&payload, 6).unwrap()
    let f1 = gzopen(c".audit/probes/zlib_gzwrite/out/out_mixed.gz".ptr, c"wb".ptr)
    if f1 == null:
        print("OPEN-FAIL-MIXED")
        return
    gzsetparams(f1, 6 as c_int, 0 as c_int)
    gzputs(f1, c"hello ".ptr)
    gzputc(f1, 104 as c_int)
    gzputs(f1, c" world\n".ptr)
    gzprintf(f1, c"%s!\n".ptr, "hello")
    gzwrite(f1, comp.ptr as *const c_void, comp.len() as c_uint)
    gzfwrite(comp.ptr as *const c_void, 1 as c_ulong, comp.len() as c_ulong, f1)
    gzflush(f1, 2 as c_int)
    gzclose(f1)
    let f2 = gzopen(c".audit/probes/zlib_gzwrite/out/out_empty.gz".ptr, c"wb".ptr)
    if f2 == null:
        print("OPEN-FAIL-EMPTY")
        return
    gzclose_w(f2)
    print("probe-gzwrite-done")

fn main:
    unsafe { run() }
