use std.zlib.defs
use std.zlib.infback

fn main:
    var stream: z_stream_s
    let win = with_alloc(32768) as *mut u8
    let rc = unsafe { inflateBackInit_(&raw mut stream as *mut z_stream_s, 15, win, c"1.3.2".ptr, sizeof[z_stream_s]() as c_int) }
    assert(rc == 0)
    print("PASS infback init rc=0")
    let erc = unsafe { inflateBackEnd(&raw mut stream as *mut z_stream_s) }
    assert(erc == 0)
    print("PASS infback end rc=0")
    with_free(win)
    print("ALL-PASS infback")
