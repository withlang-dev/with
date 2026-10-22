// Migrated from C
use std.zl.defs
use std.zl.zutil
use std.zl.deflate
use std.zl.inflate
use std.zl.infback
use std.zl.compress
use std.zl.uncompr
use std.zl.gzlib
use std.zl.gzwrite
use std.zl.gzread
use std.zl.adler32
use std.zl.crc32

pub unsafe fn gzclose(__param_file: *mut gzFile_s) -> c_int {
    var __local_state: *mut gz_state

    if ((if __param_file == null: 1 else: 0) != 0) {
        return -2
    }

    (__local_state = ((__param_file as *mut gz_state)))

    return (if (if __local_state.mode == 7247: 1 else: 0) != 0: (gzclose_r(__param_file) as c_int) else: (gzclose_w(__param_file) as c_int))

}
