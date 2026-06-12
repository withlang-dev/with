use c_import("bzlib.h")

unsafe fn same_prefix(a: *const u8, b: *const u8, n: i32) -> bool:
    var i = 0
    while i < n:
        if a[i] != b[i]:
            return false
        i = i + 1
    true

fn main:
    let input = "with bzip2 roundtrip"
    var compressed: [u8; 512] = [0 as u8; 512]
    var compressed_len: c_uint = compressed.len() as c_uint
    var output: [u8; 128] = [0 as u8; 128]
    var output_len: c_uint = output.len() as c_uint

    let rc1 = unsafe { BZ2_bzBuffToBuffCompress(&raw mut compressed[0] as *mut c_char, &raw mut compressed_len as *mut c_uint, input as *mut c_char, input.len() as c_uint, 9, 0, 30) }
    if rc1 != BZ_OK:
        print("bzip2 compress failed")
        return 1

    let rc2 = unsafe { BZ2_bzBuffToBuffDecompress(&raw mut output[0] as *mut c_char, &raw mut output_len as *mut c_uint, &raw mut compressed[0] as *mut c_char, compressed_len, 0, 0) }
    if rc2 != BZ_OK:
        print("bzip2 decompress failed")
        return 1

    if output_len != input.len() as c_uint:
        print("bzip2 length mismatch")
        return 1
    if not unsafe { same_prefix(&raw const output[0] as *const u8, input as *const u8, input.len() as i32) }:
        print("bzip2 content mismatch")
        return 1
    write("bzip2 UAT passed\n")
