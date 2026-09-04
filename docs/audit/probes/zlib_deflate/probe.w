use std.zlib
use std.libc

fn assert_bytes_eq(actual: &Vec[u8], expected: &Vec[u8]):
    assert(actual.len() == expected.len())
    var i: i64 = 0
    while i < expected.len():
        assert(actual.get(i) == expected.get(i))
        i = i + 1

unsafe fn save(path: *const i8, data: &Vec[u8]):
    let f = fopen(path, c"wb".ptr)
    if f == null:
        print("FOPEN-FAIL")
        return
    if data.len() > 0:
        fwrite(data.ptr as *const c_void, 1 as u64, data.len() as u64, f)
    fclose(f)

unsafe fn compress_case(path: *const i8, data: &Vec[u8], level: i32):
    let c = compress_level(data, level).unwrap()
    save(path, &c)
    let back = decompress(&c).unwrap()
    assert_bytes_eq(&back, data)

unsafe fn run():
    let empty: Vec[u8] = Vec.new()
    let rep: Vec[u8] = Vec.new()
    var i: i64 = 0
    while i < 3000:
        rep.push(65 as u8)
        rep.push(66 as u8)
        i = i + 1
    let inc: Vec[u8] = Vec.new()
    var j: i64 = 0
    while j < 2048:
        inc.push(((j * 31 + 17) % 251) as u8)
        j = j + 1
    compress_case(c".audit/probes/zlib_deflate/out/empty_l0.z".ptr, &empty, 0)
    compress_case(c".audit/probes/zlib_deflate/out/empty_l1.z".ptr, &empty, 1)
    compress_case(c".audit/probes/zlib_deflate/out/empty_l6.z".ptr, &empty, 6)
    compress_case(c".audit/probes/zlib_deflate/out/empty_l9.z".ptr, &empty, 9)
    compress_case(c".audit/probes/zlib_deflate/out/rep_l0.z".ptr, &rep, 0)
    compress_case(c".audit/probes/zlib_deflate/out/rep_l1.z".ptr, &rep, 1)
    compress_case(c".audit/probes/zlib_deflate/out/rep_l6.z".ptr, &rep, 6)
    compress_case(c".audit/probes/zlib_deflate/out/rep_l9.z".ptr, &rep, 9)
    compress_case(c".audit/probes/zlib_deflate/out/inc_l0.z".ptr, &inc, 0)
    compress_case(c".audit/probes/zlib_deflate/out/inc_l1.z".ptr, &inc, 1)
    compress_case(c".audit/probes/zlib_deflate/out/inc_l6.z".ptr, &inc, 6)
    compress_case(c".audit/probes/zlib_deflate/out/inc_l9.z".ptr, &inc, 9)
    let g = compress_gzip(&rep).unwrap()
    save(c".audit/probes/zlib_deflate/out/rep_gzip.gz".ptr, &g)
    let gback = decompress_gzip(&g).unwrap()
    assert_bytes_eq(&gback, &rep)
    print("probe-deflate-done")

fn main:
    unsafe { run() }
