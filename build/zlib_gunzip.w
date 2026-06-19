use std.fs
use std.process
use std.zlib.defs
use std.zlib.inflate

extern fn with_str_from_vec_u8(bytes: *const Vec[u8]) -> str

const ZLIB_MAX_OUTPUT: i64 = 64 * 1024 * 1024

fn bytes_from_str(data: str) -> Vec[u8]:
    let out: Vec[u8] = Vec.new()
    var i: i64 = 0
    while i < data.len():
        out.push(data.byte_at(i) as u8)
        i = i + 1
    out

fn bytes_to_str(data: &Vec[u8]) -> str:
    unsafe { with_str_from_vec_u8(data) }

fn bytes_data(bytes: &Vec[u8]) -> *const u8:
    bytes.ptr as *const u8

fn copy_from_raw(ptr: *const u8, len: i64) -> Vec[u8]:
    let out: Vec[u8] = Vec.new()
    var i: i64 = 0
    while i < len:
        out.push(unsafe *((ptr as i64 + i) as *const u8))
        i = i + 1
    out

fn zlib_error_message(code: i32) -> str:
    if code == Z_STREAM_ERROR:
        return "invalid zlib stream state or parameter"
    if code == Z_DATA_ERROR:
        return "invalid or corrupt zlib data"
    if code == Z_MEM_ERROR:
        return "zlib allocation failed"
    if code == Z_BUF_ERROR:
        return "zlib output buffer is too small"
    if code == Z_VERSION_ERROR:
        return "zlib version mismatch"
    "zlib operation failed"

fn decompress_gzip(data: &Vec[u8], max_output_len: i64) -> Result[Vec[u8], str]:
    if max_output_len < 0:
        return Err("zlib maximum output length must be non-negative")
    var cap: i64 = (data.len() * 3) as i64
    if cap < 1024:
        cap = 1024
    if cap > max_output_len:
        cap = max_output_len
    while true:
        var out_len = cap as c_ulong
        let out_ptr = with_alloc(cap) as *mut u8
        if out_ptr as i64 == 0:
            return Err(zlib_error_message(Z_MEM_ERROR))
        let rc = unsafe { inflate_gzip_to_buffer(out_ptr, &raw mut out_len, bytes_data(data), data.len() as c_ulong) }
        if rc == Z_OK:
            let out = copy_from_raw(out_ptr as *const u8, out_len as i64)
            with_free(out_ptr as *i8)
            return Ok(out)
        with_free(out_ptr as *i8)
        if rc != Z_BUF_ERROR:
            return Err(zlib_error_message(rc))
        if cap >= max_output_len:
            return Err("zlib decompressed output exceeds maximum length")
        cap = cap * 2
        if cap > max_output_len:
            cap = max_output_len

unsafe fn inflate_gzip_to_buffer(dest: *mut u8, dest_len: *mut c_ulong, source: *const u8, source_len: c_ulong) -> c_int:
    var stream: z_stream_s
    var left = unsafe *dest_len
    unsafe *dest_len = 0 as c_ulong
    var len = source_len
    let init_rc = inflateInit2_(&raw mut stream as *mut z_stream_s, MAX_WBITS + 16, c"1.3.2".ptr, sizeof[z_stream_s]() as c_int)
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

fn main -> i32:
    let argv = args()
    if argv.len() < 3:
        print("usage: zlib_gunzip <input.tar.gz> <output.tar>")
        return 2
    let input = read_file(argv.get(1))
    if input.len() == 0:
        print("could not read input archive")
        return 1
    let input_bytes = bytes_from_str(input)
    match decompress_gzip(&input_bytes, ZLIB_MAX_OUTPUT):
        Ok(tar_bytes) => {
            if write_file(argv.get(2), bytes_to_str(&tar_bytes)) != 0:
                print("could not write output tar")
                return 1
        }
        Err(message) => {
            print(message)
            return 1
        }
    0
