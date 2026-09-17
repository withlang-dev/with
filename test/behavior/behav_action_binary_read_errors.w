//! expect-stdout: ok

use pre_d_build_runner
use std.fs
use std.string.StringBuilder

fn exercise(method: &str, kind: &str, strict: bool):
    let label = f"binary_read_{method}_{kind}_{strict}"
    let root = p7_prepare_case(label, "binaryread")
    var bytes = StringBuilder.new()
    for byte in [0, 1, 10, 13, 26, 127, 128, 255]: bytes.push_char(byte)
    let payload = if kind == "empty": "" else: bytes.to_str()
    if kind == "binary" or kind == "empty": p7_write(root, "input.bin", payload)
    if kind == "directory": assert(mkdir_p(root ++ "/input.bin") == 0)
    p7_write(root, "out/result.bin", "preserve destination")
    var source = "use std.build\n\nfn action(ctx: ActionCtx) -> i32:\n"
    if method == "copy_file":
        source = source ++ "    ctx.fs().copy_file(\"input.bin\", \"out/result.bin\")\n"
    else:
        source = source ++ "    let bytes = ctx.fs().read_binary(\"input.bin\")\n"
        source = source ++ "    ctx.fs().write_binary(\"out/result.bin\", bytes)\n"
    source = source ++ "\npub fn build(ctx: BuildCtx) -> Build:\n"
    source = source ++ "    var out = ctx.new_build()\n"
    source = source ++ "    var target = target_new(.Action, \"read-input\", \"\").output(\"out/result.bin\")\n"
    source = source ++ "    target.action = action\n    out = out.add_target(target)\n    out.default(\"read-input\")\n"
    p7_write(root, "build.w", source)
    let args = if strict: "build\0--strict-effects\0" else: "build\0"
    let result = p7_run(root, label, args)
    if kind == "missing" or kind == "directory":
        p7_assert_failure_contains(result, method, label)
        p7_assert_failure_contains(result, "input.bin", label)
        assert(read_file(root ++ "/out/result.bin").unwrap() == "preserve destination")
    else:
        p7_assert_success(result, label)
        assert(read_file(root ++ "/out/result.bin").unwrap() == payload)

fn main:
    for strict in [false, true]:
        for method in ["copy_file", "read_binary"]:
            for kind in ["missing", "directory", "empty", "binary"]:
                exercise(method, kind, strict)
    print("ok")
