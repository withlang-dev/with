use c_import("zlib.h")

unsafe fn same_prefix(a: *const u8, b: *const u8, n: i32) -> bool:
    var i = 0
    while i < n:
        if a[i] != b[i]:
            return false
        i = i + 1
    true

fn main:
    let input = "with zlib roundtrip"
    var compressed: [u8; 256] = [0 as u8; 256]
    var compressed_len: uLongf = compressed.len() as uLongf
    var output: [u8; 128] = [0 as u8; 128]
    var output_len: uLongf = output.len() as uLongf

    let rc1 = unsafe { compress(&raw mut compressed[0] as *mut Bytef, &raw mut compressed_len as *mut uLongf, input as *const Bytef, input.len() as uLong) }
    if rc1 != Z_OK:
        print("zlib compress failed")
        return 1

    let rc2 = unsafe { uncompress(&raw mut output[0] as *mut Bytef, &raw mut output_len as *mut uLongf, &raw const compressed[0] as *const Bytef, compressed_len as uLong) }
    if rc2 != Z_OK:
        print("zlib uncompress failed")
        return 1

    if output_len != input.len() as uLongf:
        print("zlib length mismatch")
        return 1
    if not unsafe { same_prefix(&raw const output[0] as *const u8, input as *const u8, input.len() as i32) }:
        print("zlib content mismatch")
        return 1
    if unsafe { zlibVersion() } == null:
        print("zlib version missing")
        return 1
    write("zlib UAT passed\n")
