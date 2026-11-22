// Migrated from C
use std.engines.zlib.defs
use std.engines.zlib.zutil
use std.engines.zlib.deflate
use std.engines.zlib.inflate
use std.engines.zlib.infback
use std.engines.zlib.compress
use std.engines.zlib.uncompr
use std.engines.zlib.gzlib
use std.engines.zlib.gzwrite
use std.engines.zlib.gzread
use std.engines.zlib.adler32
use std.engines.zlib.crc32

// contract: stored-unknown:0 — stores an argument; ownership not modeled
pub unsafe fn gzclose(__param_file: *mut gzFile_s) -> i32 {
    var __local_state: *mut gz_state

    if (__param_file == null) {
        return -2
    }

    (__local_state = ((__param_file as *mut gz_state)))

    return (if (*__local_state).mode == 7247: (gzclose_r(__param_file) as i32) else: (gzclose_w(__param_file) as i32))

}
