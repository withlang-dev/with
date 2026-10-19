//! expect-stdout: ok

use compiler.EmbeddedClangResourceData
use compiler.Link
use std.fs

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
    print("ok")
