//! expect-stdout: ok

use pre_d_build_runner
use std.fs
use std.process

fn main:
    let case_dir = p7_prepare_case("zlib_gunzip_owned", "zlib_gunzip_owned")
    let helper = read_file(p7_abs("build/zlib_gunzip.w")).unwrap()
    assert(helper.contains("fn main -> i32:"))
    // Exercise the actual helper with small limits and early failures, without
    // adding test-only switches to its command-line interface.
    let cases = "\nfn main:\n    let size = 4 * 1024 * 1024 + 29\n    let original = Vec[u8].with_capacity(size)\n    for i in 0..size: original.push((i % 256) as u8)\n    let compressed = compress_gzip(original).unwrap()\n    assert(decompress_gzip_to_file(compressed, \"roundtrip.tar\", 8 * 1024 * 1024) == \"\")\n    let restored = read_file(\"roundtrip.tar\").unwrap()\n    assert(restored.len() == original.len())\n    for i in 0..size: assert(restored[i] == original[i])\n    let empty = compress_gzip(Vec[u8].new()).unwrap()\n    assert(decompress_gzip_to_file(empty, \"empty.tar\", 0) == \"\")\n    assert(read_file(\"empty.tar\").unwrap().len() == 0)\n    assert(decompress_gzip_to_file(compressed, \"limited.tar\", 8).contains(\"exceeds maximum\"))\n    assert(read_file(\"limited.tar\").unwrap().len() <= 8)\n    assert(decompress_gzip_to_file(compressed, \"negative.tar\", -1).contains(\"non-negative\"))\n    assert(not file_exists(\"negative.tar\"))\n    var corrupt = compressed.clone()\n    corrupt[0] = 0\n    assert(decompress_gzip_to_file(corrupt, \"corrupt.tar\", 8 * 1024 * 1024).len() > 0)\n    var truncated = compressed.clone()\n    truncated.pop()\n    assert(decompress_gzip_to_file(truncated, \"truncated.tar\", 8 * 1024 * 1024).len() > 0)\n    assert(decompress_gzip_to_file(Vec[u8].new(), \"no-input.tar\", 8).len() > 0)\n    assert(decompress_gzip_to_file(empty, \"missing/output.tar\", 8).contains(\"could not open\"))\n    if os() == \"Linux\":\n        let small = Vec[u8].new()\n        small.push(42)\n        let small_gzip = compress_gzip(small).unwrap()\n        assert(decompress_gzip_to_file(small_gzip, \"/dev/full\", 8).len() > 0)\n    print(\"gunzip cases ok\")\n"
    p7_write(case_dir, "src/main.w", "use std.zlib\nuse std.sysinfo\n" ++ helper.replace("fn main -> i32:", "fn helper_main -> i32:") ++ cases)
    let previous = env("WITH_ALLOC_NO_REUSE").clone()
    assert(set_env("WITH_ALLOC_NO_REUSE", "1") == 0)
    let result = p7_run(case_dir, "zlib_gunzip_owned", "run\0--debug-alloc\0--debug-alloc-filter=non-root\0src/main.w\0")
    assert(set_env("WITH_ALLOC_NO_REUSE", previous) == 0)
    p7_assert_success(result, "streaming gunzip ownership and failures")
    assert(result.stdout.contains("gunzip cases ok"))
    assert(result.stderr.contains("debug-alloc: leak count=0"))
    assert(not result.stderr.contains("ledger full"))
    print("ok")
