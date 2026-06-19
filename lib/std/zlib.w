// std.zlib - safe in-memory facade over the migrated zlib engine.

use std.collections
use std.result
use std.zlib.defs
use std.zlib.compress
use std.zlib.uncompr

const ZLIB_DEFAULT_MAX_OUTPUT: i64 = 64 * 1024 * 1024

pub type ZlibError {
    code: i32,
    message: str,
}

fn zlib_error(code: i32, message: str) -> ZlibError:
    ZlibError { code: code, message: message }

fn zlib_code_error(code: i32) -> ZlibError:
    if code == Z_STREAM_ERROR:
        return zlib_error(code, "invalid zlib stream state or parameter")
    if code == Z_DATA_ERROR:
        return zlib_error(code, "invalid or corrupt zlib data")
    if code == Z_MEM_ERROR:
        return zlib_error(code, "zlib allocation failed")
    if code == Z_BUF_ERROR:
        return zlib_error(code, "zlib output buffer is too small")
    if code == Z_VERSION_ERROR:
        return zlib_error(code, "zlib version mismatch")
    zlib_error(code, "zlib operation failed")

fn zlib_vec_data(bytes: &Vec[u8]) -> *const u8:
    bytes.ptr as *const u8

fn zlib_copy_from_raw(ptr: *const u8, len: i64) -> Vec[u8]:
    let out: Vec[u8] = Vec.new()
    var i: i64 = 0
    while i < len:
        out.push(unsafe *((ptr as i64 + i) as *const u8))
        i = i + 1
    out

pub fn compress(data: &Vec[u8]) -> Result[Vec[u8], ZlibError]:
    compress_level(data, Z_DEFAULT_COMPRESSION)

pub fn compress_level(data: &Vec[u8], level: i32) -> Result[Vec[u8], ZlibError]:
    if level < Z_DEFAULT_COMPRESSION or level > Z_BEST_COMPRESSION:
        return Err(zlib_error(Z_STREAM_ERROR, "zlib compression level must be -1..9"))
    var out_len = compressBound(data.len() as c_ulong)
    let out_ptr = with_alloc(out_len as i64) as *mut u8
    if out_ptr as i64 == 0:
        return Err(zlib_code_error(Z_MEM_ERROR))
    let rc = unsafe { compress2(out_ptr, &raw mut out_len, zlib_vec_data(data), data.len() as c_ulong, level as c_int) }
    if rc != Z_OK:
        with_free(out_ptr as *i8)
        return Err(zlib_code_error(rc))
    let out = zlib_copy_from_raw(out_ptr as *const u8, out_len as i64)
    with_free(out_ptr as *i8)
    Ok(out)

pub fn decompress(data: &Vec[u8]) -> Result[Vec[u8], ZlibError]:
    decompress_with_limit(data, ZLIB_DEFAULT_MAX_OUTPUT)

pub fn decompress_with_limit(data: &Vec[u8], max_output_len: i64) -> Result[Vec[u8], ZlibError]:
    if max_output_len < 0:
        return Err(zlib_error(Z_STREAM_ERROR, "zlib maximum output length must be non-negative"))
    var cap: i64 = (data.len() * 3) as i64
    if cap < 1024:
        cap = 1024
    if cap > max_output_len:
        cap = max_output_len
    while true:
        var out_len = cap as c_ulong
        let out_ptr = with_alloc(cap) as *mut u8
        if out_ptr as i64 == 0:
            return Err(zlib_code_error(Z_MEM_ERROR))
        let rc = unsafe { uncompress(out_ptr, &raw mut out_len, zlib_vec_data(data), data.len() as c_ulong) }
        if rc == Z_OK:
            let out = zlib_copy_from_raw(out_ptr as *const u8, out_len as i64)
            with_free(out_ptr as *i8)
            return Ok(out)
        with_free(out_ptr as *i8)
        if rc != Z_BUF_ERROR:
            return Err(zlib_code_error(rc))
        if cap >= max_output_len:
            return Err(zlib_error(Z_BUF_ERROR, "zlib decompressed output exceeds maximum length"))
        cap = cap * 2
        if cap > max_output_len:
            cap = max_output_len
