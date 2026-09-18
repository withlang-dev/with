//! defs probe: zlib-shared constants, C-type aliases and ctype helpers.
//! Oracle: C zlib 1.3.2 header values + ASCII table facts.

use std.zlib.defs
// NOTE: defs.w:487 calls zutil's zlibVersion() but declares no imports;
// a lone `use std.zlib.defs` fails check, so zutil is imported here.
// See finding F1 in lib__std__zlib__defs.w.md and standalone_import_error.txt.
use std.zlib.zutil


fn main:
    // return codes (zlib.h)
    assert(Z_OK == 0)
    assert(Z_STREAM_END == 1)
    assert(Z_NEED_DICT == 2)
    assert(Z_ERRNO == -1)
    assert(Z_STREAM_ERROR == -2)
    assert(Z_DATA_ERROR == -3)
    assert(Z_MEM_ERROR == -4)
    assert(Z_BUF_ERROR == -5)
    assert(Z_VERSION_ERROR == -6)
    print("ok defs return-codes")

    // compression levels / strategies / flush modes / window
    assert(Z_NO_COMPRESSION == 0)
    assert(Z_BEST_SPEED == 1)
    assert(Z_BEST_COMPRESSION == 9)
    assert(Z_DEFAULT_COMPRESSION == -1)
    assert(Z_DEFAULT_STRATEGY == 0)
    assert(Z_FILTERED == 1)
    assert(Z_HUFFMAN_ONLY == 2)
    assert(Z_RLE == 3)
    assert(Z_FIXED == 4)
    assert(Z_NO_FLUSH == 0)
    assert(Z_FINISH == 4)
    assert(MAX_WBITS == 15)
    assert(MAX_MEM_LEVEL == 9)
    print("ok defs levels")

    // version identity
    assert(ZLIB_VERSION == "1.3.2")
    assert(ZLIB_VERNUM == 0x1320)
    assert(ZLIB_VER_MAJOR == 1)
    assert(ZLIB_VER_MINOR == 3)
    assert(ZLIB_VER_REVISION == 2)
    print("ok defs version")

    // limit constants
    assert(UINT_MAX == 0xffffffff as c_uint)
    assert(INT_MAX == 2147483647)
    let ulong_all_ones: c_ulong = 0xffffffffffffffff
    assert(ULONG_MAX == ulong_all_ones)
    print("ok defs limits")

    // ctype helpers (ASCII facts)
    assert(is_alpha(65))
    assert(is_alpha(122))
    assert(not is_alpha(48))
    assert(is_digit(57))
    assert(not is_digit(65))
    assert(is_space(32))
    assert(is_space(10))
    assert(not is_space(65))
    assert(is_alnum(48))
    assert(not is_alnum(33))
    assert(is_upper(90))
    assert(not is_upper(97))
    assert(is_lower(97))
    assert(is_xdigit(70))
    assert(is_xdigit(102))
    assert(not is_xdigit(71))
    assert(is_print(126))
    assert(not is_print(31))
    assert(to_lower(65) == 97)
    assert(to_lower(97) == 97)
    assert(to_upper(122) == 90)
    assert(to_upper(90) == 90)
    print("ok defs ctype")
