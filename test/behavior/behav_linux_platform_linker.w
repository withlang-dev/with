//! expect-stdout: ok

use pre_d_build_runner
use std.fs
use std.process
use std.sysinfo

// The native Linux cc path must work with the platform toolchain alone.
// Give the child only the four system tools it needs, so an SDK's ld.lld
// elsewhere on PATH cannot hide an accidental external LLVM dependency.
fn exercise_linux:
    let root = p7_prepare_case("linux_platform_linker", "platformlinker")
    let bin = root ++ "/tools"
    assert(mkdir_p(bin) == 0)
    for name in ["cc", "as", "ld", "nm"]:
        assert(symlink("/usr/bin/" ++ name, bin ++ "/" ++ name) == 0)
    p7_write(root, "src/main.w", "fn main:\n    print(\"platform link ok\")\n")
    // Behavior fixtures run in separate processes; this environment belongs
    // only to this fixture and its synchronous child.
    for name in ["LLVM_PREFIX", "WITH_LLVM_LD", "LLVM_LD", "WITH_LIBCLANG", "LD_LIBRARY_PATH"]:
        assert(set_env(name, "") == 0)
    assert(set_env("PATH", bin) == 0)
    let result = p7_run(root, "linux_platform_linker", "run\0src/main.w\0")
    p7_assert_success(result, "native Linux without LLVM on PATH")
    assert(result.stdout.trim() == "platform link ok")

fn main:
    if os() == "Linux": exercise_linux()
    print("ok")
