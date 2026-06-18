// Migrated from C
use std.zlib.defs
use std.zlib.zutil
use std.zlib.deflate
use std.zlib.inflate
use std.zlib.infback
use std.zlib.compress
use std.zlib.uncompr
use std.zlib.gzlib
use std.zlib.gzwrite
use std.zlib.gzread
use std.zlib.adler32
use std.zlib.crc32

pub unsafe fn gzclose(__param_file: *mut gzFile_s) -> c_int {
    var __local_state: *mut gz_state

    if ((if __param_file == null: 1 else: 0) != 0) {
        return -2
    }

    (__local_state = ((__param_file as *mut gz_state)))

    var __ci_expr_ternary_0: c_int = 0

    if ((if __local_state.mode == 7247: 1 else: 0) != 0) {
        (__ci_expr_ternary_0 = ((gzclose_r(__param_file) as c_int)))
    } else {
        (__ci_expr_ternary_0 = ((gzclose_w(__param_file) as c_int)))
    }

    return __ci_expr_ternary_0


}
