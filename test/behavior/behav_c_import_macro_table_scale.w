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
    source.push_str("#define LAST(x) ((x) + _WITH_SCALE_32999)\\n")
    source.push_str("#define _WITH_PIPE (1 | 2)\\n#define PIPE(x) ((x) + _WITH_PIPE)\\n")
    source.push_str("#define _WITH_ADD(x) x + 2\\n#define PRECEDENCE(x) (3 * _WITH_ADD(x))\\n")
    source.push_str("#define _WITH_NESTED(x) (_WITH_ADD(x) + _WITH_PIPE)\\n#define NESTED(x) _WITH_NESTED(x)\\n")
    source.push_str("#define _WITH_ALIAS _WITH_NESTED\\n#define ALIAS(x) _WITH_ALIAS(x)\\n")
    source.push_str("#define SHADOW(_WITH_PIPE) ((_WITH_PIPE) + 1)\\n")
    // Constant initializers repeatedly resolve names against the registry.
    // Merely constructing the large table did not cover the Windows stall.
    for i in 0..256:
        source.push_str(f"static const int with_value_{i} = _WITH_SCALE_32999 + _WITH_SCALE_16000 + {i};\\n")
    source.push_str("\")\nfn main:\n    assert(FIRST(42) == 42)\n    assert(MIDDLE(1) == 16001)\n    assert(LAST(1) == 33000)\n    assert(PIPE(1) == 4)\n")
    source.push_str("    assert(PRECEDENCE(4) == 14)\n    assert(NESTED(1) == 6)\n    assert(ALIAS(2) == 7)\n    assert(SHADOW(9) == 10)\n")
    for i in 0..256:
        source.push_str(f"    assert(with_value_{i} == {48999 + i})\n")
    p7_write(root, "src/main.w", source.to_str())
    let result = p7_run(root, "macro-table-scale", "run\0src/main.w\0")
    p7_assert_success(result, "large macro table")
    print("ok")
