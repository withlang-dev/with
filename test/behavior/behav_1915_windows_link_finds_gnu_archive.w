//! only-on: windows
//! expect-stdout: ok

// #1915: on Windows `with get` builds a C package from source with the SDK's
// windows-gnu toolchain, and CMake names its archive GNU-style (libbz2.a).
// The link turned the package's `bz2` into `bz2.lib` and could not open it.
// A `link:` name is now found as clang's MinGW driver finds `-l`: lib<name>.a,
// <name>.lib, lib<name>.lib, <name>.a in each search path.

use pre_d_build_runner
use std.fs
use std.process

fn main:
    let case_dir = p7_prepare_case("windows_link_finds_gnu_archive", "gnuarchive")
    p7_write(case_dir, "part/part.w", "@[c_export(\"gnuarchive_value\")]\npub fn gnuarchive_value() -> i32: 41\n\nfn main:\n    print(f\"{gnuarchive_value()}\")\n")
    let obj = p7_run(case_dir, "gnuarchive_obj", "build\0part/part.w\0--emit-obj\0-o\0part.obj\0")
    p7_assert_success(obj, "part object")
    assert(mkdir_p(p7_join(case_dir, "vendor")) == 0)
    let ar = p7_run(case_dir, "gnuarchive_ar", "__ar\0qc\0vendor/libgnuarchive.a\0part.obj\0")
    p7_assert_success(ar, "libgnuarchive.a")
    p7_write(case_dir, "with.toml", "[package]\nname = \"gnuarchive\"\nversion = \"0.1.0\"\n\n[link]\nlibs = [\"gnuarchive\"]\nsearch_paths = [\"vendor\"]\n")
    p7_write(case_dir, "src/main.w", "extern fn gnuarchive_value() -> i32\n\nfn main:\n    if unsafe { gnuarchive_value() } + 1 == 42: print(\"ok\")\n")
    let built = p7_run(case_dir, "gnuarchive_build", "build\0")
    p7_assert_success(built, "program linking libgnuarchive.a")
    // The program prints ok itself (its stdout is this test's).
    var exe: Vec[str] = Vec.new()
    exe.push(p7_join(case_dir, "out/bin/gnuarchive.exe"))
    assert(run(&exe) == 0)
