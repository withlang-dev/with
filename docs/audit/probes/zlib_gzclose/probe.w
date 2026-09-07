use std.zlib.gzlib
use std.zlib.gzread
use std.zlib.gzclose
use std.libc

unsafe fn run():
    let f = gzopen(c".audit/probes/zlib_gzclose/in_py.gz".ptr, c"rb".ptr)
    if f == null:
        print("OPEN-FAIL")
        return
    let bp = with_alloc(64) as *mut u8
    if bp as i64 == 0:
        print("ALLOC-FAIL")
        return
    let n = gzread(f, bp as *mut c_void, 64 as c_uint)
    if n != 64:
        print("SHORT-READ")
        return
    let out = fopen(c".audit/probes/zlib_gzclose/out_back.bin".ptr, c"wb".ptr)
    if out == null:
        print("FOPEN-FAIL")
        return
    fwrite(bp as *const c_void, 1 as u64, 64 as u64, out)
    fclose(out)
    with_free(bp)
    gzclose(f)
    print("probe-gzclose-done")

fn main:
    unsafe { run() }
