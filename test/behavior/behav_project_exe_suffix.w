//! expect-stdout: ok

use pre_d_build_runner
use std.fs
use std.sysinfo

// A project's default program path carries `.exe` on Windows: cmd.exe and
// PowerShell run a file only by its extension, so `out\bin\app` was "not
// recognized as an internal or external command" although `with run` could
// launch it by absolute path. Elsewhere the name is bare, as before.

fn main:
    let dir = p7_prepare_case("exe_suffix", "p7exesuffix")
    p7_write(dir, "with.toml", "[package]\nname = \"p7exesuffix\"\nversion = \"0.1.0\"\n")
    p7_write(dir, "src/main.w", "fn main:\n    print(\"exe suffix\")\n")
    p7_assert_success(p7_run(dir, "exe-suffix-build", p7_build_args()), "build")
    let bare = p7_join(dir, "out/bin/p7exesuffix")
    if os() == "Windows":
        assert(file_exists(bare ++ ".exe"))
        assert(not file_exists(bare))
    else:
        assert(file_exists(bare))
        assert(not file_exists(bare ++ ".exe"))
    print("ok")
