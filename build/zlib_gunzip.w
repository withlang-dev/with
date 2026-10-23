// The SDK source gunzip helper (build/sdk.w sdk_gunzip, build/seed.w
// seed_gunzip_to_tar): `zlib_gunzip <input.tar.gz> <output.tar>`.
//
// A build helper is compiled by the driver, the pinned seed, and reaches
// zlib through std's facade (`std.zlib`), which every seed embeds. It never
// names an engine module (`std.engines.zlib.*`): those are the tree's
// corpus, and a corpus re-promotion that used a newer language feature
// (union `zeroed()`, #2556) made the helper uncompilable under the pinned
// Linux and Windows seeds, which broke `:deps` and corpus-c-model on a
// fresh host (#2582). The corpus-reference helper (lib/std/build.w
// build_zlib_gunzip_source) is written the same way. The facade has no
// streaming inflate, so the archive is decompressed in memory; the largest
// input is the prebuilt SDK archive. behav_zlib_gunzip_owned exercises
// decompress_gzip_to_file's limits and failures.
use std.fs
use std.libc
use std.process
use std.string
use std.zlib

const ZLIB_MAX_OUTPUT: i64 = 8589934592

fn bytes_from_str(data: &str) -> List[u8]:
    let out: List[u8] = List.new()
    var i: i64 = 0
    while i < data.len():
        out.push(data[i])
        i = i + 1
    out

type OutputFile { handle: *mut c_void }

impl OutputFile:
    mut fn close():
        if self.handle == null: return 0
        let file: *mut c_void = self.handle
        self.handle = null
        fclose(file)

impl Drop for OutputFile:
    move fn drop():
        if self.handle != null: fclose(self.handle)

fn write_all(file: &OutputFile, bytes: &List[u8]):
    var written: i64 = 0
    while written < bytes.len():
        let remaining = bytes.len() - written
        let n = fwrite(&raw const bytes[written] as *const c_void, 1, remaining as u64, file.handle)
        if n == 0:
            return false
        written = written + n as i64
    true

// Decompresses `data` (a gzip stream) into `output_path`, at most
// `max_output_len` bytes; "" on success, else the reason. The output file
// exists once the path opened, empty when the stream was refused.
fn decompress_gzip_to_file(data: &List[u8], output_path: &str, max_output_len: i64):
    if max_output_len < 0:
        return "zlib maximum output length must be non-negative"
    let output_cstr = match output_path.to_cstring():
        Ok(c) => c
        Err(_) => return "output path contains interior NUL"
    let handle = fopen(output_cstr.as_cstr().ptr(), c"wb".ptr)
    if handle == null: return "could not open output tar"
    var file = OutputFile { handle }
    let err = match decompress_gzip_with_limit(data, max_output_len):
        Ok(tar_bytes) => if write_all(file, tar_bytes): "" else: "could not write output tar"
        Err(zerr) => zerr.message
    let close_rc = file.close()
    if err.len() > 0: return err
    if close_rc != 0: return "could not close output tar"
    ""

fn main -> i32:
    let argv = args()
    if argv.len() < 3:
        print("usage: zlib_gunzip <input.tar.gz> <output.tar>")
        return 2
    let input = match read_file(argv[1]):
        Ok(text) => text
        Err(err) => {
            print("could not read input archive: " ++ err.message())
            return 1
        }
    if input.len() == 0:
        print("input archive is empty")
        return 1
    let input_bytes = bytes_from_str(input)
    let err = decompress_gzip_to_file(&input_bytes, argv[2], ZLIB_MAX_OUTPUT)
    if err.len() > 0:
        print(err)
        return 1
    0
