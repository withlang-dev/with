use std.fs
use std.libc
use std.process
use std.string
use std.zlib.defs
use std.zlib.inflate

const ZLIB_MAX_OUTPUT: i64 = 8589934592
const ZLIB_CHUNK_SIZE: i64 = 4 * 1024 * 1024
const ZLIB_MAX_INPUT = (0 as c_uint) -% 1

fn bytes_from_str(data: &str) -> Vec[u8]:
    let out: Vec[u8] = Vec.new()
    var i: i64 = 0
    while i < data.len():
        out.push(data[i])
        i = i + 1
    out

type OutputFile { handle: *mut c_void }

impl OutputFile:
    mut fn close():
        if self.handle == null: return 0
        let handle = self.handle
        self.handle = null
        fclose(handle)

impl Drop for OutputFile:
    move fn drop():
        if self.handle != null: fclose(self.handle)

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

fn write_all(file: &OutputFile, bytes: &Vec[u8], len: i64):
    assert(len >= 0 and len <= bytes.len())
    var written: i64 = 0
    while written < len:
        let remaining = len - written
        let n = fwrite(&raw const bytes[written] as *const c_void, 1, remaining as u64, file.handle)
        if n == 0:
            return false
        written = written + n as i64
    true

fn inflate_gzip(data: &Vec[u8], file: &OutputFile, max_output_len: i64):
    var output = Vec[u8].with_capacity(ZLIB_CHUNK_SIZE)
    for _ in 0..ZLIB_CHUNK_SIZE: output.push(0)
    var stream: z_stream_s
    // zlib requires a stable stream address. It stays in this scope from
    // initialization through the deferred End call, including early returns.
    let init_rc = unsafe { inflateInit2_(&raw mut stream, MAX_WBITS + 16, c"1.3.2".ptr, sizeof[z_stream_s]() as c_int) }
    if init_rc != Z_OK:
        return zlib_error_message(init_rc)
    defer: assert(unsafe { inflateEnd(&raw mut stream) } == Z_OK)
    stream.avail_in = 0
    var source_offset: i64 = 0
    var total_out: i64 = 0
    while true:
        if stream.avail_in == 0 and source_offset < data.len():
            let remaining = data.len() - source_offset
            let avail = if remaining > ZLIB_MAX_INPUT as i64: ZLIB_MAX_INPUT else: remaining as c_uint
            // The C ABI spells next_in mutable; inflate only reads it. The
            // borrowed input remains alive and is never resized or modified.
            stream.next_in = &raw const data[source_offset] as *mut u8
            stream.avail_in = avail
            source_offset = source_offset + avail as i64
        stream.next_out = &raw mut output[0]
        stream.avail_out = ZLIB_CHUNK_SIZE as c_uint
        // output owns an initialized, fixed-size writable buffer. zlib sees
        // exactly that capacity; no references to its contents cross this call.
        let err = unsafe { inflate(&raw mut stream, Z_NO_FLUSH) }
        let produced = ZLIB_CHUNK_SIZE - stream.avail_out as i64
        if produced > 0:
            if produced > max_output_len - total_out:
                return "zlib decompressed output exceeds maximum length"
            if not write_all(file, output, produced):
                return "could not write output tar"
            total_out = total_out + produced
        if err == Z_STREAM_END:
            return ""
        if err == Z_NEED_DICT:
            return zlib_error_message(Z_DATA_ERROR)
        if err != Z_OK:
            return zlib_error_message(err)
        if produced == 0 and stream.avail_in == 0 and source_offset >= data.len():
            return zlib_error_message(Z_BUF_ERROR)

fn decompress_gzip_to_file(data: &Vec[u8], output_path: &str, max_output_len: i64):
    if max_output_len < 0:
        return "zlib maximum output length must be non-negative"
    let output_cstr = match output_path.to_cstring():
        Ok(c) => c
        Err(_) => return "output path contains interior NUL"
    let handle = fopen(output_cstr.as_cstr().ptr(), c"wb".ptr)
    if handle == null: return "could not open output tar"
    var file = OutputFile { handle }
    let err = inflate_gzip(data, file, max_output_len)
    let close_rc = file.close()
    if err.len() > 0: return err
    if close_rc != 0: return "could not close output tar"
    ""

fn main -> i32:
    let argv = args()
    if argv.len() < 3:
        print("usage: zlib_gunzip <input.tar.gz> <output.tar>")
        return 2
    let input = match read_file(argv.get(1)):
        Ok(text) => text
        Err(err) => {
            print("could not read input archive: " ++ err.message())
            return 1
        }
    if input.len() == 0:
        print("input archive is empty")
        return 1
    let input_bytes = bytes_from_str(input)
    let err = decompress_gzip_to_file(&input_bytes, argv.get(2), ZLIB_MAX_OUTPUT)
    if err.len() > 0:
        print(err)
        return 1
    0
