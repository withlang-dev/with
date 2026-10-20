//! expect-stdout: ok

use compiler.EmbeddedClangResourceData
use compiler.Link
use std.fs
use std.process

// A cross compiler link runs the host's lld-link, but its LLVM archives and
// Windows C runtime belong to the target SDK named by llvm_ld.rsp. Deriving
// the SDK from the linker executable made the windows-aarch64 seed look for
// its target C runtime inside the Linux host SDK (run 39212329480).

fn put(path: &str, text: &str):
    assert(write_file(path, text) == 0)

fn has_arg(command: &LinkStageCommand, needle: &str) -> bool:
    for i in 0..command.args.len():
        if command.args[i].contains(needle): return true
    false

fn main:
    let root = "out/test-scratch/link-windows-cross-sdk"
    let host = root ++ "/host-sdk"
    let target = root ++ "/target-sdk"
    assert(mkdir_p(host ++ "/lib") == 0)
    put(host ++ "/lib/libclang.a", "host\n")
    assert(mkdir_p(target ++ "/lib") == 0)
    put(target ++ "/lib/libclang.a", "target\n")
    for arch in ["x86_64", "aarch64"]:
        let libc = target ++ "/libc/windows/" ++ arch ++ "-w64-mingw32/lib"
        assert(mkdir_p(libc) == 0)
        put(libc ++ "/crt2.o", "crt\n")
        let builtins = target ++ "/lib/clang/" ++ embedded_clang_resource_version() ++ "/lib/windows"
        assert(mkdir_p(builtins) == 0)
        put(builtins ++ "/libclang_rt.builtins-" ++ arch ++ ".a", "builtins\n")

    let rsp = root ++ "/llvm_ld.rsp"
    put(rsp, target ++ "/lib/libclang.a\n")
    var extras: List[str] = List.new()
    extras.push("@" ++ rsp)
    let no_libs: List[str] = List.new()
    let no_args: List[str] = List.new()
    let command = link_stage_make_windows_llvm_link_command("lld-link", host, "main.o", "main.exe", extras, no_libs, no_args)
    assert(command.linker == "lld-link")
    assert(has_arg(&command, target ++ "/libc/windows/"))
    assert(not has_arg(&command, host ++ "/libc/windows/"))
    // The image names its PDB by file name, not by the absolute path it was
    // linked at: the same inputs link to the same bytes in any directory.
    assert(has_arg(&command, "/pdbaltpath:%_PDB%"))
    assert(command.cwd.len() == 0)

    // Under a prefix map the link runs from the mapped root, names what is
    // under it relative to it, and gives the PDB the map's <to> (#2016).
    let case_root = "C:\\cases\\a"
    assert(set_env("WITH_FILE_PREFIX_MAP", case_root ++ "=/mapped") == 0)
    let mapped = link_stage_make_windows_llvm_link_command("lld-link", host, case_root ++ "\\out\\bin\\tool.o", "C:/cases/a/out/bin/tool", extras, no_libs, no_args)
    assert(set_env("WITH_FILE_PREFIX_MAP", "") == 0)
    assert(mapped.cwd == "C:/cases/a")
    assert(has_arg(&mapped, "/out:out/bin/tool"))
    assert(has_arg(&mapped, "/pdb:out/bin/tool.pdb"))
    assert(has_arg(&mapped, "/pdbsourcepath:/mapped"))
    for arg in mapped.args:
        assert(not arg.contains("cases"))

    // The c_import parse reads the same SDK libc as the link: on aarch64
    // too when the SDK carries it (run 39296788835 parsed mingw-w64's
    // headers as the host MSVC target instead), never from an SDK without
    // the arch's crt, and never off Windows.
    assert(link_stage_windows_uses_sdk_libc_for(true, "aarch64", target))
    assert(not link_stage_windows_uses_sdk_libc_for(true, "aarch64", host))
    assert(link_stage_windows_uses_sdk_libc_for(true, "x86_64", host))
    assert(not link_stage_windows_uses_sdk_libc_for(false, "aarch64", target))
    print("ok")
