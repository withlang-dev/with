//! expect-stdout: ok

use pre_d_build_runner
use std.string.StringBuilder

fn main:
    let root = p7_prepare_case("c_import_macro_table_scale", "macrotablescale")
    var source = StringBuilder.new()
    source.push_str("use c_import(\"")
    // Comparable to the Windows header closure that stalled bzip2/libcurl.
    // Keep dependencies at both ends and in the middle of the value table.
    for i in 0..33000:
        source.push_str(f"#define _WITH_SCALE_{i} {i}\\n")
    source.push_str("#define FIRST(x) ((x) + _WITH_SCALE_0)\\n")
    source.push_str("#define MIDDLE(x) ((x) + _WITH_SCALE_16000)\\n")
    source.push_str("#define LAST(x) ((x) + _WITH_SCALE_32999)\\n\")\n")
    source.push_str("fn main:\n    assert(FIRST(42) == 42)\n    assert(MIDDLE(1) == 16001)\n    assert(LAST(1) == 33000)\n")
    p7_write(root, "src/main.w", source.to_str())
    let result = p7_run(root, "macro-table-scale", "run\0src/main.w\0")
    p7_assert_success(result, "large macro table")
    print("ok")
