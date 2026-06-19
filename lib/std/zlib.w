// std.zlib - safe in-memory facade over the migrated zlib engine.

use std.collections
use std.result
use std.zlib.defs
use std.zlib.compress
use std.zlib.deflate
use std.zlib.uncompr
use std.zlib.inflate

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

pub fn compress_gzip(data: &Vec[u8]) -> Result[Vec[u8], ZlibError]:
    compress_gzip_level(data, Z_DEFAULT_COMPRESSION)

pub fn compress_gzip_level(data: &Vec[u8], level: i32) -> Result[Vec[u8], ZlibError]:
    if level < Z_DEFAULT_COMPRESSION or level > Z_BEST_COMPRESSION:
        return Err(zlib_error(Z_STREAM_ERROR, "zlib compression level must be -1..9"))
    if data.len() as c_ulong > UINT_MAX as c_ulong:
        return Err(zlib_error(Z_BUF_ERROR, "zlib gzip input is too large"))
    var stream: z_stream_s
    let init_rc = unsafe { deflateInit2_(&raw mut stream as *mut z_stream_s, level as c_int, Z_DEFLATED, MAX_WBITS + 16, 8, Z_DEFAULT_STRATEGY, c"1.3.2".ptr, sizeof[z_stream_s]() as c_int) }
    if init_rc != Z_OK:
        return Err(zlib_code_error(init_rc))
    let out_len = unsafe { deflateBound(&raw mut stream as *mut z_stream_s, data.len() as c_ulong) }
    if out_len > UINT_MAX as c_ulong:
        let _ = unsafe { deflateEnd(&raw mut stream as *mut z_stream_s) }
        return Err(zlib_error(Z_BUF_ERROR, "zlib gzip output is too large"))
    let out_ptr = with_alloc(out_len as i64) as *mut u8
    if out_ptr as i64 == 0:
        let _ = unsafe { deflateEnd(&raw mut stream as *mut z_stream_s) }
        return Err(zlib_code_error(Z_MEM_ERROR))
    stream.next_in = zlib_vec_data(data) as *mut u8
    stream.avail_in = data.len() as c_uint
    stream.next_out = out_ptr
    stream.avail_out = out_len as c_uint
    let rc = unsafe { deflate(&raw mut stream as *mut z_stream_s, Z_FINISH) }
    let total_out = stream.total_out
    let end_rc = unsafe { deflateEnd(&raw mut stream as *mut z_stream_s) }
    if rc != Z_STREAM_END:
        with_free(out_ptr as *i8)
        return Err(zlib_code_error(rc))
    if end_rc != Z_OK:
        with_free(out_ptr as *i8)
        return Err(zlib_code_error(end_rc))
    let out = zlib_copy_from_raw(out_ptr as *const u8, total_out as i64)
    with_free(out_ptr as *i8)
    Ok(out)

pub fn decompress(data: &Vec[u8]) -> Result[Vec[u8], ZlibError]:
    decompress_with_limit(data, ZLIB_DEFAULT_MAX_OUTPUT)

pub fn decompress_with_limit(data: &Vec[u8], max_output_len: i64) -> Result[Vec[u8], ZlibError]:
    decompress_window_bits(data, max_output_len, MAX_WBITS)

pub fn decompress_gzip(data: &Vec[u8]) -> Result[Vec[u8], ZlibError]:
    decompress_gzip_with_limit(data, ZLIB_DEFAULT_MAX_OUTPUT)

pub fn decompress_gzip_with_limit(data: &Vec[u8], max_output_len: i64) -> Result[Vec[u8], ZlibError]:
    decompress_window_bits(data, max_output_len, MAX_WBITS + 16)

fn decompress_window_bits(data: &Vec[u8], max_output_len: i64, window_bits: i32) -> Result[Vec[u8], ZlibError]:
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
        let rc = unsafe { zlib_inflate_to_buffer(out_ptr, &raw mut out_len, zlib_vec_data(data), data.len() as c_ulong, window_bits as c_int) }
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

unsafe fn zlib_inflate_to_buffer(dest: *mut u8, dest_len: *mut c_ulong, source: *const u8, source_len: c_ulong, window_bits: c_int) -> c_int:
    var stream: z_stream_s
    var left = unsafe *dest_len
    unsafe *dest_len = 0 as c_ulong
    var len = source_len
    let init_rc = inflateInit2_(&raw mut stream as *mut z_stream_s, window_bits, c"1.3.2".ptr, sizeof[z_stream_s]() as c_int)
    if init_rc != Z_OK:
        return init_rc
    stream.next_out = dest
    stream.avail_out = 0 as c_uint
    stream.next_in = source as *mut u8
    stream.avail_in = 0 as c_uint
    var err = Z_OK
    while err == Z_OK:
        if stream.avail_out == 0:
            stream.avail_out = if left > UINT_MAX as c_ulong: UINT_MAX as c_uint else: left as c_uint
            left = left - stream.avail_out as c_ulong
        if stream.avail_in == 0:
            stream.avail_in = if len > UINT_MAX as c_ulong: UINT_MAX as c_uint else: len as c_uint
            len = len - stream.avail_in as c_ulong
        err = inflate(&raw mut stream as *mut z_stream_s, Z_NO_FLUSH)
    unsafe *dest_len = stream.total_out
    inflateEnd(&raw mut stream as *mut z_stream_s)
    if err == Z_STREAM_END:
        return Z_OK
    if err == Z_NEED_DICT:
        return Z_DATA_ERROR
    if err == Z_BUF_ERROR and left + stream.avail_out as c_ulong != 0:
        return Z_DATA_ERROR
    err
