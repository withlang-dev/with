use std.zlib.gzlib
use std.zlib.gzread
use std.zlib.gzclose

fn main:
    let f = unsafe { gzopen(c"/tmp/zlib_audit/t.gz".ptr, c"rb".ptr) }
    assert(f as i64 != 0)
    print("PASS gzlib gzopen rb")
    assert(unsafe { gzeof(f) } == 0)
    print("PASS gzlib gzeof=0 at start")
    let e = unsafe { gzerror(f, 0 as *mut c_int) }
    assert(e as i64 != 0)
    print("PASS gzlib gzerror non-null")
    assert(unsafe { gzdirect(f) } == 0)
    print("PASS gzlib gzdirect=0 for gzip")
    let c = unsafe { gzclose_r(f) }
    assert(c == 0)
    print("PASS gzlib gzclose_r")
    let bad = unsafe { gzopen(c"/tmp/zlib_audit/no-such-file.gz".ptr, c"rb".ptr) }
    assert(bad as i64 == 0)
    print("PASS gzlib gzopen missing=null")
    print("ALL-PASS gzlib")
