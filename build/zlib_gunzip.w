use std.fs
use std.libc
use std.process
use std.string
use std.zlib.defs
use std.zlib.inflate

const ZLIB_MAX_OUTPUT: i64 = 8589934592
const ZLIB_CHUNK_SIZE: i64 = 4 * 1024 * 1024

fn bytes_from_str(data: str) -> Vec[u8]:
    let out: Vec[u8] = Vec.new()
    var i: i64 = 0
    while i < data.len():
        out.push(data.byte_at(i) as u8)
        i = i + 1
    out

fn bytes_data(bytes: &Vec[u8]) -> *const u8:
    bytes.ptr as *const u8

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

unsafe fn write_all(file: *mut c_void, ptr: *const u8, len: i64) -> bool:
    var written: i64 = 0
    while written < len:
        let remaining = len - written
        let n = fwrite((ptr as i64 + written) as *const c_void, 1, remaining as u64, file)
        if n == 0:
            return false
        written = written + n as i64
    true

unsafe fn cleanup_stream(file: *mut c_void, out_ptr: *mut u8, stream: *mut z_stream_s, initialized: bool) -> Unit:
    if initialized:
        let _end = inflateEnd(stream)
    if out_ptr as i64 != 0:
        with_free(out_ptr as *i8)
    if file as i64 != 0:
        let _close = fclose(file)

fn decompress_gzip_to_file(data: &Vec[u8], output_path: str, max_output_len: i64) -> str:
    if max_output_len < 0:
        return "zlib maximum output length must be non-negative"
    let output_cstr = match output_path.to_cstring():
        Ok(c) => c
        Err(_) => return "output path contains interior NUL"
    let file = fopen(output_cstr.as_cstr().ptr(), c"wb".ptr)
    if file as i64 == 0:
        return "could not open output tar"
    let out_ptr = with_alloc(ZLIB_CHUNK_SIZE) as *mut u8
    if out_ptr as i64 == 0:
        unsafe { cleanup_stream(file, out_ptr, null, false) }
        return zlib_error_message(Z_MEM_ERROR)
    var stream: z_stream_s
    let init_rc = unsafe { inflateInit2_(&raw mut stream as *mut z_stream_s, MAX_WBITS + 16, c"1.3.2".ptr, sizeof[z_stream_s]() as c_int) }
    if init_rc != Z_OK:
        unsafe { cleanup_stream(file, out_ptr, &raw mut stream as *mut z_stream_s, false) }
        return zlib_error_message(init_rc)
    let source = bytes_data(data)
    stream.next_in = source as *mut u8
    stream.avail_in = 0 as c_uint
    var source_offset: i64 = 0
    var total_out: i64 = 0
    while true:
        if stream.avail_in == 0 and source_offset < data.len():
            let remaining = data.len() - source_offset
            let avail = if remaining > UINT_MAX as i64: UINT_MAX as c_uint else: remaining as c_uint
            stream.next_in = (source as i64 + source_offset) as *mut u8
            stream.avail_in = avail
            source_offset = source_offset + avail as i64
        stream.next_out = out_ptr
        stream.avail_out = ZLIB_CHUNK_SIZE as c_uint
        let err = unsafe { inflate(&raw mut stream as *mut z_stream_s, Z_NO_FLUSH) }
        let produced = ZLIB_CHUNK_SIZE - stream.avail_out as i64
        if produced > 0:
            if not unsafe { write_all(file, out_ptr as *const u8, produced) }:
                unsafe { cleanup_stream(file, out_ptr, &raw mut stream as *mut z_stream_s, true) }
                return "could not write output tar"
            total_out = total_out + produced
            if total_out > max_output_len:
                unsafe { cleanup_stream(file, out_ptr, &raw mut stream as *mut z_stream_s, true) }
                return "zlib decompressed output exceeds maximum length"
        if err == Z_STREAM_END:
            unsafe { cleanup_stream(file, out_ptr, &raw mut stream as *mut z_stream_s, true) }
            return ""
        if err == Z_NEED_DICT:
            unsafe { cleanup_stream(file, out_ptr, &raw mut stream as *mut z_stream_s, true) }
            return zlib_error_message(Z_DATA_ERROR)
        if err != Z_OK:
            unsafe { cleanup_stream(file, out_ptr, &raw mut stream as *mut z_stream_s, true) }
            return zlib_error_message(err)
        if produced == 0 and stream.avail_in == 0 and source_offset >= data.len():
            unsafe { cleanup_stream(file, out_ptr, &raw mut stream as *mut z_stream_s, true) }
            return zlib_error_message(Z_BUF_ERROR)

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
    let err = decompress_gzip_to_file(&input_bytes, argv.get(2), ZLIB_MAX_OUTPUT)
    if err.len() > 0:
        print(err)
        return 1
    0
