use std.build
use build.runtime
use build.selfhost
use build.abi
use build.pcre2
use build.zlib
use build.seed
use build.emit_c
use build.compiler
use build.clang_resource
use build.retention
use build.release_uat
use build.package
use build.sdk
use std.sysinfo
fn build_owned_text(s: &str): s ++ ""

fn build_project_dirname(path: &str) -> str:
    var last_slash = -1
    for i in 0..path.len() as i32:
        if path.byte_at(i as i64) == 47:
            last_slash = i
    if last_slash < 0:
        return "."
    if last_slash == 0:
        return "/"
    path.slice(0, last_slash as i64)

fn with_object_target(name: &str, compiler: &str, source: &str, output: &str, opt: &str, dep: &str) -> Target:
    var target = target_new(.Action, build_owned_text(name), "").output(build_owned_text(output))
    target.action = run_with_compiler_build_action
    target = target.compiler(compiler)
    target = target.input(build_owned_text(source))
    target = target.arg("--emit-obj")
    target = target.arg("--no-prelude")
    target = target.arg(build_owned_text(opt))
    target = target.write_scope("out/command/" ++ name)
    target = target.write_scope(build_project_dirname(output))
    target = target.allow_parallel()
    if dep.len() > 0:
        target = target.dep(build_owned_text(dep))
    target

fn with_ir_target(name: &str, compiler: &str, source: &str, output: &str, dep: &str) -> Target:
    var target = target_new(.Action, build_owned_text(name), "").output(build_owned_text(output))
    target.action = run_with_compiler_ir_action
    target = target.compiler(compiler)
    target = target.input(build_owned_text(source))
    target = target.arg("--no-prelude")
    target = target.write_scope(build_project_dirname(output))
    target = target.write_scope("out/command/" ++ name)
    target = target.allow_parallel()
    if dep.len() > 0:
        target = target.dep(build_owned_text(dep))
    target

fn with_ir_target_overflow(name: &str, compiler: &str, source: &str, output: &str, dep: &str, overflow: &str) -> Target:
    var target = with_ir_target(name, compiler, source, output, dep)
    target = target.arg("overflow=" ++ overflow)
    target

fn run_cross_unsupported_action(ctx: ActionCtx) -> i32:
    let args = ctx.args()
    let target = if args.len() > 0: build_owned_text(args.get(0)) else: ""
    if target.len() == 0:
        ctx.diagnostics().error("cross: cross-target compilation is not implemented yet; set CROSS_TARGET=<triple> or use `with build --target <triple>` for the compiler diagnostic")
    else:
        ctx.diagnostics().error("cross: cross-target compilation for '" ++ target ++ "' is not implemented yet")
    1

// ── Cross-target (linux) helpers ────────────────────────────────────
// Two supported cross tags: "linux_x86_64" and "linux_aarch64". Each
// gets a full runtime/bridge/embed/rsp target set under
// out/lib/cross/<tag>/ and a group (":cross-rt" / ":cross-rt-arm").

fn cross_dir(tag: &str) -> str:
    "out/lib/cross/" ++ tag

fn cross_triple(tag: &str) -> str:
    if tag == "linux_aarch64":
        return "aarch64-unknown-linux-gnu"
    "x86_64-unknown-linux-gnu"

fn cross_platform_source(tag: &str) -> str:
    if tag == "linux_aarch64":
        return "rt/linux_aarch64.w"
    "rt/linux_x86_64.w"

fn cross_platform_obj(tag: &str) -> str:
    if tag == "linux_aarch64":
        return "rt_linux_aarch64.o"
    "rt_linux_x86_64.o"

fn cross_platform_symbol(tag: &str) -> str:
    if tag == "linux_aarch64":
        return "rt_linux_aarch64_o"
    "rt_linux_x86_64_o"

fn cross_llvm_prefix(tag: &str) -> str:
    let arch_tag = if tag == "linux_aarch64": "linux-aarch64" else: "linux-x86_64"
    ".deps/llvm-" ++ compiler_llvm_version() ++ "-" ++ arch_tag

// A runtime/bridge object compiled FOR the cross tag by the freshly
// built native compiler (dep "build"), landing in cross_dir(tag).
fn cross_object_target_named(tag: &str, name: &str, source: &str, obj_name: &str, opt: &str) -> Target:
    var target = with_object_target(name, release_compiler_bin("with"), source, cross_dir(tag) ++ "/" ++ obj_name, opt, "build")
    target = target.arg("--target=" ++ cross_triple(tag))
    target

fn cross_object_target(tag: &str, name: &str, source: &str, opt: &str) -> Target:
    let base = comp_path_basename(source)
    let stem = if base.ends_with(".w"): base.slice(0, base.len() - 2) else: base
    cross_object_target_named(tag, name, source, stem ++ ".o", opt)

fn cross_fiber_asm_source(tag: &str) -> str:
    if tag == "linux_aarch64":
        return "runtime/fiber_asm_linux_aarch64.s"
    "runtime/fiber_asm_linux_x86_64.s"

// Register the full cross runtime/bridge/embed/rsp target set for one
// cross tag under name prefix `p`, grouped as `group_name`.
fn add_cross_rt_targets(out0: Build, tag: &str, p: &str, group_name: &str) -> Build:
    var out = out0
    let dir = cross_dir(tag)
    let triple = cross_triple(tag)
    out = out.add_target(cross_object_target(tag, p ++ "rt-core-object", "rt/rt_core.w", "-O2"))
    out = out.add_target(cross_object_target_named(tag, p ++ "rt-platform-object", cross_platform_source(tag), cross_platform_obj(tag), "-O2"))
    out = out.add_target(cross_object_target(tag, p ++ "cimport-stubs-object", "rt/cimport_stubs.w", "-O1"))
    var cross_compat = cross_object_target_named(tag, p ++ "compat-runtime-object", "out/gen/compat_runtime.w", "compat_runtime.o", "-O1")
    cross_compat = cross_compat.dep("compat-runtime-source")
    out = out.add_target(cross_compat)
    out = out.add_target(cross_object_target(tag, p ++ "panic-runtime-object", "rt/panic_runtime.w", "-O1"))
    out = out.add_target(cross_object_target(tag, p ++ "fiber-stubs-object", "rt/fiber_stubs.w", "-O1"))
    out = out.add_target(cross_object_target(tag, p ++ "channel-runtime-object", "rt/channel_runtime.w", "-O1"))
    out = out.add_target(cross_object_target(tag, p ++ "fiber-runtime-object", "rt/fiber_runtime.w", "-O1"))
    out = out.add_target(cross_object_target_named(tag, p ++ "fiber-core-object", "rt/fiber_core_darwin.w", "fiber.o", "-O1"))
    out = out.add_target(cross_object_target_named(tag, p ++ "llvm-bridge-object", "src/compiler/LlvmBridge.w", "llvm_bridge.o", "-O1"))
    out = out.add_target(cross_object_target_named(tag, p ++ "clang-bridge-object", "src/compiler/ClangBridge.w", "clang_bridge.o", "-O1"))

    // regex: whole-module IR (like the native regex-runtime-ir path) so
    // the migrated pcre2 modules land in one object; the IR carries the
    // target triple and CompileLlvmIrObject compiles it as written.
    var cross_regex_ir = with_ir_target_overflow(p ++ "regex-runtime-ir", release_compiler_bin("with"), "rt/regex_runtime.w", "out/tmp/" ++ tag ++ "_regex_runtime.ll", "build", "wrap")
    cross_regex_ir = cross_regex_ir.arg("--target=" ++ triple)
    out = out.add_target(cross_regex_ir)
    var cross_regex = target_new(.CompileLlvmIrObject, p ++ "regex-runtime-object", "out/tmp/" ++ tag ++ "_regex_runtime.ll").output(dir ++ "/regex_runtime.o")
    cross_regex = cross_regex.dep(p ++ "regex-runtime-ir")
    out = out.add_target(cross_regex)

    var cross_fiber_asm = target_new(.CompileAsmObject, p ++ "fiber-asm-object", cross_fiber_asm_source(tag)).output(dir ++ "/fiber_asm.o")
    cross_fiber_asm = cross_fiber_asm.arg("triple=" ++ triple)
    out = out.add_target(cross_fiber_asm)

    var cross_embedded = target_new(.EmbedObjectFiles, p ++ "embedded-objects-asm", build_owned_text(tag)).output(dir ++ "/embedded_objects.s")
    cross_embedded = cross_embedded.input(dir ++ "/cimport_stubs.o")
    cross_embedded = cross_embedded.arg("cimport_stubs_o")
    cross_embedded = cross_embedded.input(dir ++ "/compat_runtime.o")
    cross_embedded = cross_embedded.arg("compat_runtime_o")
    cross_embedded = cross_embedded.input(dir ++ "/panic_runtime.o")
    cross_embedded = cross_embedded.arg("panic_runtime_o")
    cross_embedded = cross_embedded.input(dir ++ "/regex_runtime.o")
    cross_embedded = cross_embedded.arg("regex_runtime_o")
    cross_embedded = cross_embedded.input(dir ++ "/fiber_stubs.o")
    cross_embedded = cross_embedded.arg("fiber_stubs_o")
    cross_embedded = cross_embedded.input(dir ++ "/channel_runtime.o")
    cross_embedded = cross_embedded.arg("channel_runtime_o")
    cross_embedded = cross_embedded.input(dir ++ "/fiber_runtime.o")
    cross_embedded = cross_embedded.arg("fiber_runtime_o")
    cross_embedded = cross_embedded.input(dir ++ "/fiber.o")
    cross_embedded = cross_embedded.arg("fiber_o")
    cross_embedded = cross_embedded.input(dir ++ "/fiber_asm.o")
    cross_embedded = cross_embedded.arg("fiber_asm_o")
    cross_embedded = cross_embedded.input(dir ++ "/rt_core.o")
    cross_embedded = cross_embedded.arg("rt_core_o")
    cross_embedded = cross_embedded.input(dir ++ "/" ++ cross_platform_obj(tag))
    cross_embedded = cross_embedded.arg(cross_platform_symbol(tag))
    cross_embedded = cross_embedded.dep(p ++ "cimport-stubs-object")
    cross_embedded = cross_embedded.dep(p ++ "compat-runtime-object")
    cross_embedded = cross_embedded.dep(p ++ "panic-runtime-object")
    cross_embedded = cross_embedded.dep(p ++ "regex-runtime-object")
    cross_embedded = cross_embedded.dep(p ++ "fiber-stubs-object")
    cross_embedded = cross_embedded.dep(p ++ "channel-runtime-object")
    cross_embedded = cross_embedded.dep(p ++ "fiber-runtime-object")
    cross_embedded = cross_embedded.dep(p ++ "fiber-core-object")
    cross_embedded = cross_embedded.dep(p ++ "fiber-asm-object")
    cross_embedded = cross_embedded.dep(p ++ "rt-core-object")
    cross_embedded = cross_embedded.dep(p ++ "rt-platform-object")
    out = out.add_target(cross_embedded)

    var cross_embedded_obj = target_new(.CompileAsmObject, p ++ "embedded-objects-object", dir ++ "/embedded_objects.s").output(dir ++ "/embedded_objects.o")
    cross_embedded_obj = cross_embedded_obj.arg("triple=" ++ triple)
    cross_embedded_obj = cross_embedded_obj.dep(p ++ "embedded-objects-asm")
    out = out.add_target(cross_embedded_obj)

    var cross_ld_rsp = target_new(.Action, p ++ "llvm-link-metadata", "").output(dir ++ "/llvm_ld.rsp")
    cross_ld_rsp.action = run_cross_linux_llvm_link_metadata_action
    cross_ld_rsp = cross_ld_rsp.arg(build_owned_text(tag))
    cross_ld_rsp = cross_ld_rsp.write_scope(dir)
    cross_ld_rsp = cross_ld_rsp.write_scope("out/command/" ++ p ++ "llvm-link-metadata")
    out = out.add_target(cross_ld_rsp)

    var cross_rt = target_new(.Group, build_owned_text(group_name), "")
    cross_rt = cross_rt.dep(p ++ "embedded-objects-object")
    cross_rt = cross_rt.dep(p ++ "llvm-bridge-object")
    cross_rt = cross_rt.dep(p ++ "clang-bridge-object")
    cross_rt = cross_rt.dep(p ++ "llvm-link-metadata")
    out.add_target(cross_rt)

// Generate cross/<tag>/llvm_ld.rsp: the tag's linux LLVM SDK static
// clang+LLVM archives plus the linux system libraries, mirroring what
// the native linux ld_rsp branch of run_generate_llvm_link_metadata_action
// writes. Fails loudly when that SDK is not in .deps.
fn run_cross_linux_llvm_link_metadata_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let args = ctx.args()
    let tag = if args.len() > 0: build_owned_text(args.get(0)) else: "linux_x86_64"
    let output_path = ctx.output()
    let lib_dir = cross_llvm_prefix(tag) ++ "/lib"
    let libclang = lib_dir ++ "/libclang.a"
    if not fs.host_exists(libclang):
        ctx.diagnostics().error("cross-llvm-link-metadata: missing " ++ libclang ++ "; extract or build the " ++ cross_llvm_prefix(tag) ++ " LLVM SDK first")
        return 1
    let lib_files = fs.host_list_files(lib_dir)
    if lib_files.len() == 0:
        ctx.diagnostics().error("cross-llvm-link-metadata: could not list: " ++ lib_dir)
        return 1
    var clang_archives: Vec[str] = Vec.new()
    var llvm_archives: Vec[str] = Vec.new()
    for i in 0..lib_files.len() as i32:
        let path = lib_files.get(i as i64)
        let name = comp_path_basename(path)
        if name.ends_with(".a"):
            if name.starts_with("libclang") and path != libclang:
                clang_archives.push(build_owned_text(path))
            else:
                if name.starts_with("libLLVM"):
                    llvm_archives.push(build_owned_text(path))
    var ld_rsp = comp_rsp_path(libclang) ++ "\n"
    let sorted_clang = comp_sort_strings(clang_archives)
    for i in 0..sorted_clang.len() as i32:
        ld_rsp = ld_rsp ++ comp_rsp_path(sorted_clang.get(i as i64)) ++ "\n"
    let sorted_llvm = comp_sort_strings(llvm_archives)
    for i in 0..sorted_llvm.len() as i32:
        ld_rsp = ld_rsp ++ comp_rsp_path(sorted_llvm.get(i as i64)) ++ "\n"
    ld_rsp = ld_rsp ++ "-Bstatic\n-lstdc++\n-lgcc\n-lgcc_eh\n-Bdynamic\n-lpthread\n-ldl\n-lm\n-lz\n-lzstd\n-lxml2\n"
    if fs.write_text(output_path, ld_rsp) != 0:
        ctx.diagnostics().error("cross-llvm-link-metadata: could not write: " ++ output_path)
        return 1
    0

// ── Cross-target (windows_x86_64) helpers ───────────────────────────

fn cross_windows_dir() -> str:
    "out/lib/cross/windows_x86_64"

fn cross_windows_triple() -> str:
    "x86_64-pc-windows-msvc"

fn cross_windows_llvm_prefix() -> str:
    ".deps/llvm-" ++ compiler_llvm_version() ++ "-windows-x86_64-msvc"

fn cross_windows_object_target_named(name: &str, source: &str, obj_name: &str, opt: &str) -> Target:
    var target = with_object_target(name, release_compiler_bin("with"), source, cross_windows_dir() ++ "/" ++ obj_name, opt, "build")
    target = target.arg("--target=" ++ cross_windows_triple())
    target

fn cross_windows_object_target(name: &str, source: &str, opt: &str) -> Target:
    let base = comp_path_basename(source)
    let stem = if base.ends_with(".w"): base.slice(0, base.len() - 2) else: base
    cross_windows_object_target_named(name, source, stem ++ ".o", opt)

// Generate cross/windows_x86_64/llvm_ld.rsp: the windows LLVM SDK's
// static clang+LLVM import/static archives, in lld-link positional
// form (one .lib per line, no GNU flags). The MSVC CRT and Windows
// SDK import libraries are appended by the windows link recipe
// (link_stage_make_windows_llvm_link_command) from the WITH_WINDOWS_*
// lib dirs, so they are not repeated here.
fn run_cross_windows_llvm_link_metadata_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let output_path = ctx.output()
    let lib_dir = cross_windows_llvm_prefix() ++ "/lib"
    let libclang = lib_dir ++ "/libclang.lib"
    if not fs.host_exists(libclang):
        ctx.diagnostics().error("cross-windows-llvm-link-metadata: missing " ++ libclang ++ "; extract the with-llvm-sdk-" ++ compiler_llvm_version() ++ "-windows-x86_64 release asset into .deps/")
        return 1
    let lib_files = fs.host_list_files(lib_dir)
    if lib_files.len() == 0:
        ctx.diagnostics().error("cross-windows-llvm-link-metadata: could not list: " ++ lib_dir)
        return 1
    var clang_archives: Vec[str] = Vec.new()
    var llvm_archives: Vec[str] = Vec.new()
    for i in 0..lib_files.len() as i32:
        let path = lib_files.get(i as i64)
        let name = comp_path_basename(path)
        if name.ends_with(".lib"):
            if (name.starts_with("clang") or name.starts_with("libclang")) and path != libclang:
                clang_archives.push(build_owned_text(path))
            else:
                if name.starts_with("LLVM") and name != "LLVM-C.lib":
                    llvm_archives.push(build_owned_text(path))
    var ld_rsp = comp_rsp_path(libclang) ++ "\n"
    let sorted_clang = comp_sort_strings(clang_archives)
    for i in 0..sorted_clang.len() as i32:
        ld_rsp = ld_rsp ++ comp_rsp_path(sorted_clang.get(i as i64)) ++ "\n"
    let sorted_llvm = comp_sort_strings(llvm_archives)
    for i in 0..sorted_llvm.len() as i32:
        ld_rsp = ld_rsp ++ comp_rsp_path(sorted_llvm.get(i as i64)) ++ "\n"
    if fs.write_text(output_path, ld_rsp) != 0:
        ctx.diagnostics().error("cross-windows-llvm-link-metadata: could not write: " ++ output_path)
        return 1
    0

// ── Cross-target (windows_aarch64) helpers ──────────────────────────

fn cross_windows_aarch64_dir() -> str:
    "out/lib/cross/windows_aarch64"

fn cross_windows_aarch64_triple() -> str:
    "aarch64-pc-windows-msvc"

fn cross_windows_aarch64_llvm_prefix() -> str:
    ".deps/llvm-" ++ compiler_llvm_version() ++ "-windows-aarch64-msvc"

fn cross_windows_aarch64_object_target_named(name: &str, source: &str, obj_name: &str, opt: &str) -> Target:
    var target = with_object_target(name, release_compiler_bin("with"), source, cross_windows_aarch64_dir() ++ "/" ++ obj_name, opt, "build")
    target = target.arg("--target=" ++ cross_windows_aarch64_triple())
    target

fn cross_windows_aarch64_object_target(name: &str, source: &str, opt: &str) -> Target:
    let base = comp_path_basename(source)
    let stem = if base.ends_with(".w"): base.slice(0, base.len() - 2) else: base
    cross_windows_aarch64_object_target_named(name, source, stem ++ ".o", opt)

// Generate cross/windows_aarch64/llvm_ld.rsp — arm64 sibling of
// run_cross_windows_llvm_link_metadata_action; identical .lib selection
// against the windows-aarch64 SDK prefix.
fn run_cross_windows_aarch64_llvm_link_metadata_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let output_path = ctx.output()
    let lib_dir = cross_windows_aarch64_llvm_prefix() ++ "/lib"
    let libclang = lib_dir ++ "/libclang.lib"
    if not fs.host_exists(libclang):
        ctx.diagnostics().error("cross-windows-aarch64-llvm-link-metadata: missing " ++ libclang ++ "; extract the with-llvm-sdk-" ++ compiler_llvm_version() ++ "-windows-aarch64 release asset into .deps/")
        return 1
    let lib_files = fs.host_list_files(lib_dir)
    if lib_files.len() == 0:
        ctx.diagnostics().error("cross-windows-aarch64-llvm-link-metadata: could not list: " ++ lib_dir)
        return 1
    var clang_archives: Vec[str] = Vec.new()
    var llvm_archives: Vec[str] = Vec.new()
    for i in 0..lib_files.len() as i32:
        let path = lib_files.get(i as i64)
        let name = comp_path_basename(path)
        if name.ends_with(".lib"):
            if (name.starts_with("clang") or name.starts_with("libclang")) and path != libclang:
                clang_archives.push(build_owned_text(path))
            else:
                if name.starts_with("LLVM") and name != "LLVM-C.lib":
                    llvm_archives.push(build_owned_text(path))
    var ld_rsp = comp_rsp_path(libclang) ++ "\n"
    let sorted_clang = comp_sort_strings(clang_archives)
    for i in 0..sorted_clang.len() as i32:
        ld_rsp = ld_rsp ++ comp_rsp_path(sorted_clang.get(i as i64)) ++ "\n"
    let sorted_llvm = comp_sort_strings(llvm_archives)
    for i in 0..sorted_llvm.len() as i32:
        ld_rsp = ld_rsp ++ comp_rsp_path(sorted_llvm.get(i as i64)) ++ "\n"
    if fs.write_text(output_path, ld_rsp) != 0:
        ctx.diagnostics().error("cross-windows-aarch64-llvm-link-metadata: could not write: " ++ output_path)
        return 1
    0

fn empty_file_target(name: &str, output: &str) -> Target:
    var target = target_new(.Action, build_owned_text(name), "").output(build_owned_text(output))
    target.action = run_write_empty_file_action
    target = target.write_scope(build_project_dirname(output))
    target

// Every platform runtime object the compiler can serve from its own binary.
// src/compiler/Link.w declares an extern per entry, so EVERY host must define
// ALL of them: the host's own object carries real content and the rest are
// zero-length placeholders. A host that omits one cannot link a compiler that
// references it -- the failure surfaces far away, as
// `lld-link/ld.lld: undefined symbol: with_embedded_rt_<platform>_o_start`
// while linking stage1. Adding a platform means adding it here and in Link.w.
fn embedded_platform_symbols() -> Vec[str]:
    let out: Vec[str] = Vec.new()
    out.push("rt_darwin_aarch64_o")
    out.push("rt_linux_x86_64_o")
    out.push("rt_linux_aarch64_o")
    out.push("rt_windows_x86_64_o")
    out.push("rt_windows_aarch64_o")
    out

// "rt_linux_aarch64_o" -> "<dir>/empty_rt_linux_aarch64.bin"
fn empty_platform_blob_path(dir: &str, sym: &str) -> str:
    dir ++ "/empty_" ++ sym.slice(0, sym.len() - 2) ++ ".bin"

fn empty_platform_blob_target(prefix: &str, sym: &str) -> str:
    prefix ++ sym


fn target_with_embedded_stdlib_inputs(target: Target, ctx: &BuildCtx) -> Target:
    var out = target
    let files = ctx.fs().list_files("lib/std")
    for i in 0..files.len() as i32:
        let path = files.get(i as i64)
        if path.ends_with(".w") and not path.starts_with("lib/std/re/"):
            out = out.input(build_owned_text(path))
    out

fn target_with_embedded_runtime_inputs(target: Target, ctx: &BuildCtx) -> Target:
    var out = target
    let files = ctx.fs().list_files("rt")
    for i in 0..files.len() as i32:
        let path = files.get(i as i64)
        if path.ends_with(".w"):
            out = out.input(build_owned_text(path))
    out

fn target_with_compiler_c_export_audit_inputs(target: Target, ctx: &BuildCtx) -> Target:
    var out = target
    let roots: Vec[str] = Vec.new()
    roots.push("src")
    roots.push("rt")
    roots.push("lib/std")
    for ri in 0..roots.len() as i32:
        let files = ctx.fs().list_files(roots.get(ri as i64))
        for fi in 0..files.len() as i32:
            let path = files.get(fi as i64)
            if path.ends_with(".w"):
                out = out.input(build_owned_text(path))
    out

fn target_with_compiler_source_inputs(target: Target, ctx: &BuildCtx) -> Target:
    var out = target
    let roots: Vec[str] = Vec.new()
    roots.push("src")
    roots.push("rt")
    roots.push("lib/std")
    // build.w / build/*.w are deliberately NOT inputs: the stage compile
    // never reads them, and the action-code signature (#686) already tracks
    // the action's own module closure. Declaring them re-created the
    // rebuild-the-world-on-any-build-edit tax.
    for ri in 0..roots.len() as i32:
        let files = ctx.fs().list_files(roots.get(ri as i64))
        for fi in 0..files.len() as i32:
            let path = files.get(fi as i64)
            if path.ends_with(".w"):
                out = out.input(build_owned_text(path))
    out

fn build_project_trim_line(text: &str) -> str:
    var end = 0
    while end < text.len() as i32:
        let ch = text.byte_at(end as i64)
        if ch == 10 or ch == 13:
            break
        end = end + 1
    var start = 0
    while start < end:
        let ch = text.byte_at(start as i64)
        if ch != 9 and ch != 32:
            break
        start = start + 1
    while end > start:
        let ch = text.byte_at((end - 1) as i64)
        if ch != 9 and ch != 32:
            break
        end = end - 1
    text.slice(start as i64, end as i64)

fn target_with_version_inputs(target: Target, ctx: &BuildCtx) -> Target:
    var out = target
    out = out.arg("version-env=" ++ env("WITH_VERSION"))
    let fs = ctx.fs()
    if not fs.exists(".git/HEAD"):
        return out
    out = out.input(".git/HEAD")
    let head = build_project_trim_line(fs.read_text(".git/HEAD"))
    if head.starts_with("ref: "):
        let ref_path = ".git/" ++ head.slice(5, head.len())
        if fs.exists(ref_path):
            out = out.input(ref_path)
        else if fs.exists(".git/packed-refs"):
            out = out.input(".git/packed-refs")
    out

fn target_with_live_targets(target: Target, graph: &Build) -> Target:
    var out = target
    for i in 0..graph.targets.len() as i32:
        out = out.arg("live-target=" ++ graph.targets.get(i as i64).name)
    out

type HostRuntimeSpec:
    platform_source: str
    compat_source: str
    bootstrap_platform_object: str
    platform_object: str
    platform_install_object: str
    platform_symbol: str
    fiber_core_source: str
    fiber_asm_source: str

fn host_exe_suffix() -> str:
    if os() == "Windows":
        return ".exe"
    ""

fn host_bin(path: &str) -> str:
    path ++ host_exe_suffix()

fn bootstrap_compiler_bin(name: &str) -> str:
    host_bin("out/bootstrap/bin/" ++ name)

fn stage_compiler_bin(name: &str) -> str:
    host_bin("out/stage/bin/" ++ name)

fn stage_compiler_obj(name: &str) -> str:
    "out/stage/bin/" ++ name

fn release_compiler_bin(name: &str) -> str:
    host_bin("out/release/bin/" ++ name)

fn release_platform_asset_bin() -> str:
    let host_os = os()
    let host_arch = arch()
    if host_os == "Macos" and comp_arch_is_aarch64(host_arch):
        return "out/release/with-darwin-aarch64"
    if host_os == "Linux" and host_arch == "x86_64":
        return "out/release/with-linux-x86_64"
    if host_os == "Windows" and host_arch == "x86_64":
        return "out/release/with-windows-x86_64.exe"
    if host_os == "Windows" and (host_arch == "armv8" or host_arch == "aarch64"):
        return "out/release/with-windows-aarch64.exe"
    release_compiler_bin("with")

// The platform asset target only exists when the asset is a distinct copy of
// the release compiler; on unknown hosts release_platform_asset_bin() falls
// back to the compiler path itself and there is nothing separate to produce.
fn release_platform_asset_is_distinct() -> bool:
    release_platform_asset_bin() != release_compiler_bin("with")

fn release_uat_platform_asset_dep(t: Target) -> Target:
    if release_platform_asset_is_distinct():
        return t.dep("release-platform-asset")
    t

fn host_runtime_spec() -> HostRuntimeSpec:
    if os() == "Linux" and comp_arch_is_aarch64(arch()):
        return HostRuntimeSpec {
            platform_source: "rt/linux_aarch64.w",
            compat_source: "rt/compat_runtime.w",
            bootstrap_platform_object: "out/bootstrap-lib/rt_linux_aarch64.o",
            platform_object: "out/lib/rt_linux_aarch64.o",
            platform_install_object: "rt_linux_aarch64.o",
            platform_symbol: "rt_linux_aarch64_o",
            fiber_core_source: "rt/fiber_core_darwin.w",
            fiber_asm_source: "runtime/fiber_asm_linux_aarch64.s",
        }
    if os() == "Linux" and arch() == "x86_64":
        return HostRuntimeSpec {
            platform_source: "rt/linux_x86_64.w",
            compat_source: "rt/compat_runtime.w",
            bootstrap_platform_object: "out/bootstrap-lib/rt_linux_x86_64.o",
            platform_object: "out/lib/rt_linux_x86_64.o",
            platform_install_object: "rt_linux_x86_64.o",
            platform_symbol: "rt_linux_x86_64_o",
            fiber_core_source: "rt/fiber_core_darwin.w",
            fiber_asm_source: "runtime/fiber_asm_linux_x86_64.s",
        }
    if os() == "Windows" and arch() == "x86_64":
        return HostRuntimeSpec {
            platform_source: "rt/windows_x86_64.w",
            compat_source: "rt/compat_runtime.w",
            bootstrap_platform_object: "out/bootstrap-lib/rt_windows_x86_64.o",
            platform_object: "out/lib/rt_windows_x86_64.o",
            platform_install_object: "rt_windows_x86_64.o",
            platform_symbol: "rt_windows_x86_64_o",
            fiber_core_source: "rt/fiber_core_windows.w",
            fiber_asm_source: "runtime/fiber_asm_windows_x86_64.s",
        }
    if os() == "Windows" and (arch() == "armv8" or arch() == "aarch64"):
        return HostRuntimeSpec {
            platform_source: "rt/windows_aarch64.w",
            compat_source: "rt/compat_runtime.w",
            bootstrap_platform_object: "out/bootstrap-lib/rt_windows_aarch64.o",
            platform_object: "out/lib/rt_windows_aarch64.o",
            platform_install_object: "rt_windows_aarch64.o",
            platform_symbol: "rt_windows_aarch64_o",
            fiber_core_source: "rt/fiber_core_windows.w",
            fiber_asm_source: "runtime/fiber_asm_windows_aarch64.s",
        }
    HostRuntimeSpec {
        platform_source: "rt/darwin_aarch64.w",
        compat_source: "rt/compat_runtime.w",
        bootstrap_platform_object: "out/bootstrap-lib/rt_darwin_aarch64.o",
        platform_object: "out/lib/rt_darwin_aarch64.o",
        platform_install_object: "rt_darwin_aarch64.o",
        platform_symbol: "rt_darwin_aarch64_o",
        fiber_core_source: "rt/fiber_core_darwin.w",
        fiber_asm_source: "runtime/fiber_asm_aarch64.s",
    }

fn release_asset_for_host() -> str:
    if os() == "Linux" and arch() == "x86_64":
        return "with-linux-x86_64"
    if os() == "Macos" and comp_arch_is_aarch64(arch()):
        return "with-darwin-aarch64"
    if os() == "Windows" and arch() == "x86_64":
        return "with-windows-x86_64.exe"
    if os() == "Windows" and (arch() == "armv8" or arch() == "aarch64"):
        return "with-windows-aarch64.exe"
    "with-darwin-aarch64"

// "with-darwin-aarch64" -> "darwin-aarch64"
fn release_platform_tag() -> str:
    let asset = release_asset_for_host()
    if asset.starts_with("with-"):
        var tag = asset.slice(5, asset.len())
        if tag.ends_with(".exe"):
            tag = tag.slice(0, tag.len() - 4)
        return tag
    asset

fn supported_release_platform_tag() -> str:
    if os() == "Linux" and arch() == "x86_64":
        return "linux-x86_64"
    if os() == "Macos" and comp_arch_is_aarch64(arch()):
        return "darwin-aarch64"
    if os() == "Windows" and arch() == "x86_64":
        return "windows-x86_64"
    if os() == "Windows" and (arch() == "armv8" or arch() == "aarch64"):
        return "windows-aarch64"
    ""

// ".deps/llvm-<ver>-<host>" -> "llvm-<ver>-<host>"
fn llvm_sdk_dir_basename() -> str:
    let prefix = compiler_default_llvm_prefix()
    if prefix.starts_with(".deps/"):
        return prefix.slice(6, prefix.len())
    prefix

fn llvm_sdk_asset_for_host() -> str:
    "with-llvm-sdk-" ++ compiler_llvm_version() ++ "-" ++ release_platform_tag() ++ ".tar.gz"

fn release_package_asset_for_platform(platform: &str) -> str:
    if platform == "darwin-aarch64":
        return "with-darwin-aarch64"
    if platform == "linux_x86_64" or platform == "linux-x86_64":
        return "with-linux-x86_64"
    if platform == "windows_x86_64" or platform == "windows-x86_64":
        return "with-windows-x86_64.exe"
    if platform == "windows_aarch64" or platform == "windows-aarch64":
        return "with-windows-aarch64.exe"
    "with-unsupported"

fn package_platform_target(name: &str, platform: &str, ctx: &BuildCtx) -> Target:
    let asset = release_package_asset_for_platform(platform)
    var target = target_new(.Action, build_owned_text(name), "").output("out/release/" ++ name ++ ".passed")
    target.action = run_package_platform_release_action
    target = target.arg(asset)
    target = target.arg(build_owned_text(platform))
    target = target.arg(release_compiler_bin("with"))
    target = target.arg(compiler_default_llvm_prefix())
    target = target.input("src/version")
    target = target.input(release_compiler_bin("with"))
    target = target.input("build/package.w")
    target = target.extra_output("out/release/" ++ asset)
    target = target.extra_output("out/release/" ++ asset ++ ".sha256")
    target = target.write_scope("out/release")
    target = target.write_scope("out/command/" ++ name)
    target = target.timeout(600000)
    target = target_with_version_inputs(move target, ctx)
    if supported_release_platform_tag() == platform:
        target = target.dep("build")
        target = target.dep("fixpoint")
        target = target.dep("release-uat")
    target

fn package_current_host_target() -> Target:
    var target = target_new(.Group, "package-current-host", "")
    let platform = supported_release_platform_tag()
    if platform == "darwin-aarch64":
        return target.dep("package-darwin-aarch64")
    if platform == "linux-x86_64":
        return target.dep("package-linux-x86_64")
    if platform == "windows-x86_64":
        return target.dep("package-windows-x86_64")
    if platform == "windows-aarch64":
        return target.dep("package-windows-aarch64")
    target.dep("package-darwin-aarch64")

fn package_llvm_sdk_platform_target(name: &str, platform: &str, prefix: &str, build_cache: &str) -> Target:
    let asset = sdk_asset_for_platform(platform)
    let sdk_base = "llvm-" ++ compiler_llvm_version() ++ "-" ++ sdk_host_tag_for_platform(platform)
    var target = target_new(.Action, build_owned_text(name), "").output("out/release/" ++ name ++ ".passed")
    target.action = run_package_llvm_sdk_action
    target = target.arg(build_owned_text(platform))
    target = target.arg(build_owned_text(prefix))
    target = target.arg(build_owned_text(build_cache))
    target = target.arg(asset)
    target = target.arg(sdk_base)
    target = target.input(build_owned_text(prefix))
    target = target.input(build_owned_text(build_cache))
    target = target.input("build/sdk.w")
    target = target.extra_output("out/release/" ++ asset)
    target = target.extra_output("out/release/" ++ asset ++ ".sha256")
    target = target.extra_output("out/release/" ++ asset ++ ".manifest")
    target = target.write_scope("out/release")
    target = target.write_scope("out/command/" ++ name)
    target.timeout(1800000)

fn package_llvm_sdk_current_host_target() -> Target:
    var target = target_new(.Group, "package-llvm-sdk", "")
    let platform = sdk_current_platform()
    if platform == "darwin-aarch64":
        return target.dep("package-llvm-sdk-darwin-aarch64")
    if platform == "linux-x86_64":
        return target.dep("package-llvm-sdk-linux-x86_64")
    if platform == "linux-aarch64":
        return target.dep("package-llvm-sdk-linux-aarch64")
    if platform == "windows-x86_64":
        return target.dep("package-llvm-sdk-windows-x86_64")
    if platform == "windows-aarch64":
        return target.dep("package-llvm-sdk-windows-aarch64")
    target.dep("package-llvm-sdk-darwin-aarch64")

fn sdk_source_target(name: &str, url: &str, sha256: &str, archive: &str, source_root: &str, source_dir: &str, marker: &str) -> Target:
    var target = target_new(.Action, build_owned_text(name), "").output(build_owned_text(marker))
    target.action = run_sdk_source_tar_gz_action
    target = target.arg(build_owned_text(url))
    target = target.arg(build_owned_text(sha256))
    target = target.arg(build_owned_text(archive))
    target = target.arg(build_owned_text(source_root))
    target = target.arg(build_owned_text(source_dir))
    target = target.input("build/https_fetch.w")
    target = target.input("build/zlib_gunzip.w")
    target = target.write_scope(build_owned_text(source_root))
    target = target.write_scope("out/command/" ++ name)
    target = target.allow_network()
    target.timeout(1800000)

fn sdk_bootstrap_prefix_arg(ctx: &BuildCtx, platform: &str) -> str:
    let explicit = ctx.env_input("SDK_BOOTSTRAP_PREFIX")
    if explicit.len() > 0:
        return explicit
    let llvm_prefix = ctx.env_input("LLVM_PREFIX")
    if llvm_prefix.len() > 0:
        return llvm_prefix
    sdk_default_prefix_for_platform(platform)

fn sdk_output_prefix_arg(ctx: &BuildCtx, platform: &str) -> str:
    let explicit = ctx.env_input("SDK_OUTPUT_PREFIX")
    if explicit.len() > 0:
        return explicit
    sdk_output_prefix_for_platform(platform)

fn sdk_build_root_arg(ctx: &BuildCtx, platform: &str) -> str:
    let explicit = ctx.env_input("SDK_BUILD_ROOT")
    if explicit.len() > 0:
        return explicit
    sdk_output_build_root_for_platform(platform)

fn sdk_jobs_arg(ctx: &BuildCtx) -> str:
    ctx.env_input("PARALLEL_JOBS")

fn sdk_ninja_target(ctx: &BuildCtx) -> Target:
    let platform = sdk_current_platform()
    let bootstrap_prefix = sdk_bootstrap_prefix_arg(ctx, platform)
    let output_prefix = sdk_output_prefix_arg(ctx, platform)
    let build_root = sdk_build_root_arg(ctx, platform)
    var target = target_new(.Action, "sdk-ninja", "").output(output_prefix ++ "/bin/ninja" ++ host_exe_suffix())
    target.action = run_sdk_ninja_action
    target = target.arg(bootstrap_prefix)
    target = target.arg(output_prefix)
    target = target.arg(sdk_ninja_source_dir())
    target = target.arg(build_root ++ "/ninja-" ++ sdk_host_tag_for_platform(platform))
    target = target.arg(sdk_jobs_arg(ctx))
    target = target.input(sdk_ninja_source_marker())
    target = target.input(bootstrap_prefix)
    target = target.input("build/sdk.w")
    target = target.write_scope(output_prefix)
    target = target.write_scope(build_root)
    target = target.write_scope("out/command/sdk-ninja")
    target = target.dep("sdk-ninja-source")
    target.timeout(1800000)

fn sdk_cmake_target(ctx: &BuildCtx) -> Target:
    let platform = sdk_current_platform()
    let bootstrap_prefix = sdk_bootstrap_prefix_arg(ctx, platform)
    let output_prefix = sdk_output_prefix_arg(ctx, platform)
    let build_root = sdk_build_root_arg(ctx, platform)
    var target = target_new(.Action, "sdk-cmake", "").output(output_prefix ++ "/bin/cmake" ++ host_exe_suffix())
    target.action = run_sdk_cmake_action
    target = target.arg(bootstrap_prefix)
    target = target.arg(output_prefix)
    target = target.arg(sdk_cmake_source_dir())
    target = target.arg(build_root ++ "/cmake-" ++ sdk_host_tag_for_platform(platform))
    target = target.arg(sdk_jobs_arg(ctx))
    target = target.input(sdk_cmake_source_marker())
    target = target.input(output_prefix ++ "/bin/ninja" ++ host_exe_suffix())
    target = target.input(bootstrap_prefix)
    target = target.input("build/sdk.w")
    target = target.write_scope(output_prefix)
    target = target.write_scope(build_root)
    target = target.write_scope("out/command/sdk-cmake")
    target = target.dep("sdk-ninja")
    target = target.dep("sdk-cmake-source")
    target.timeout(3600000)

fn sdk_llvm_target(ctx: &BuildCtx) -> Target:
    let platform = sdk_current_platform()
    let bootstrap_prefix = sdk_bootstrap_prefix_arg(ctx, platform)
    let output_prefix = sdk_output_prefix_arg(ctx, platform)
    let build_root = sdk_build_root_arg(ctx, platform)
    var target = target_new(.Action, "sdk-llvm", "").output(if platform == "windows-x86_64" or platform == "windows-aarch64": output_prefix ++ "/lib/libclang.lib" else: output_prefix ++ "/lib/libclang.a")
    target.action = run_sdk_llvm_action
    target = target.arg(bootstrap_prefix)
    target = target.arg(output_prefix)
    target = target.arg(sdk_llvm_source_dir())
    target = target.arg(build_root ++ "/llvm-" ++ compiler_llvm_version() ++ "-" ++ sdk_host_tag_for_platform(platform))
    target = target.arg(sdk_jobs_arg(ctx))
    target = target.arg(ctx.env_input("LLVM_TARGETS_TO_BUILD"))
    target = target.arg(ctx.env_input("SDKROOT"))
    target = target.arg(ctx.env_input("MACOSX_DEPLOYMENT_TARGET"))
    target = target.arg(ctx.env_input("SDK_WINDOWS_MT"))
    target = target.input(sdk_llvm_source_marker())
    target = target.input(output_prefix ++ "/bin/cmake" ++ host_exe_suffix())
    target = target.input(output_prefix ++ "/bin/ninja" ++ host_exe_suffix())
    target = target.input(bootstrap_prefix)
    target = target.input("build/sdk.w")
    target = target.write_scope(output_prefix)
    target = target.write_scope(build_root)
    target = target.write_scope("out/command/sdk-llvm")
    target = target.dep("sdk-cmake")
    target = target.dep("sdk-llvm-source")
    target.timeout(21600000)

fn sdk_group_target() -> Target:
    var target = target_new(.Group, "sdk", "")
    target = target.dep("sdk-ninja")
    target = target.dep("sdk-cmake")
    target.dep("sdk-llvm")

fn sdk_package_target(ctx: &BuildCtx) -> Target:
    let platform = sdk_current_platform()
    var target = package_llvm_sdk_platform_target("sdk-package", platform, sdk_output_prefix_arg(ctx, platform), sdk_output_llvm_cache_for_platform(platform))
    target.dep("sdk")

fn install_file_target(name: &str, source: &str, dest: &str, mode: &str, dep: &str) -> Target:
    var target = target_new(.Install, build_owned_text(name), build_owned_text(source)).output(build_owned_text(dest))
    target = target.input(build_owned_text(source))
    target = target.arg(build_owned_text(mode))
    if dep.len() > 0:
        target = target.dep(build_owned_text(dep))
    target

fn build_project_join(left: &str, right: &str) -> str:
    if left.len() == 0:
        return build_owned_text(right)
    if right.len() == 0:
        return build_owned_text(left)
    if left.ends_with("/"):
        return left ++ right
    left ++ "/" ++ right

fn build_project_abs(root: &str, path: &str) -> str:
    if path.len() > 0 and path.byte_at(0) == 47:
        return build_owned_text(path)
    build_project_join(root, path)

fn build_trim_trailing_line_endings(text: &str) -> str:
    var end = text.len()
    while end > 0:
        let ch = text.byte_at(end - 1)
        if ch != 10 and ch != 13:
            break
        end = end - 1
    text.slice(0, end)

fn build_replace_once(text: &str, needle: &str, replacement: &str) -> str:
    let idx = text.find(needle)
    if idx < 0:
        return ""
    text.slice(0, idx) ++ replacement ++ text.slice(idx + needle.len(), text.len())

// The compiler source imports four build-generated modules; a repo fixture
// that runs `with check src/main.w` needs every one of them or the check
// dies on the import (#932). Returns "" on success, else the failing step.
fn build_copy_generated_compiler_modules(fs: &ToolFs, repo_copy: &str) -> str:
    if fs.mkdir_all(build_project_join(repo_copy, "out/gen/compiler")) != 0:
        return "could not create embedded gen directory"
    let names = "EmbeddedStdlibData EmbeddedRuntimeData EmbeddedClangResourceData EmbeddedBundlesData"
    for name in names.split(" "):
        let rel = "out/gen/compiler/" ++ name ++ ".w"
        if fs.write_text(build_project_join(repo_copy, rel), fs.read_text(rel)) != 0:
            return "could not copy generated module " ++ rel
    ""

fn issue61_fail(ctx: &ActionCtx, message: &str) -> i32:
    ctx.diagnostics().error("issue61-regression: " ++ message)
    1

fn issue61_regression_action(ctx: ActionCtx) -> i32:
    let inputs = ctx.inputs()
    if inputs.len() == 0:
        return issue61_fail(ctx, "missing compiler input")
    let fs = ctx.fs()
    let output_dir = ctx.output()
    if fs.mkdir_all(output_dir) != 0:
        return issue61_fail(ctx, "could not create output directory: " ++ output_dir)

    if os() == "Windows":
        print("issue61-regression: skipped on Windows (#809)")
        let _ = fs.write_text(build_project_join(output_dir, ".stamp"), "ok")
        return 0

    let root = ctx.project_info().project_root()
    let compiler_path = build_project_abs(root, inputs.get(0))
    if not fs.exists(inputs.get(0)):
        return issue61_fail(ctx, "missing compiler: " ++ inputs.get(0))

    let repo_copy = build_project_join(output_dir, "repo")
    if fs.exists(repo_copy) and fs.remove_tree(repo_copy) != 0:
        return issue61_fail(ctx, "could not remove existing repo copy: " ++ repo_copy)
    if fs.mkdir_all(repo_copy) != 0:
        return issue61_fail(ctx, "could not create repo copy directory: " ++ repo_copy)

    if fs.copy_tree("src", build_project_join(repo_copy, "src")) != 0:
        return issue61_fail(ctx, "could not copy src into repo fixture")
    let copied_seed = build_project_join(repo_copy, "src/main")
    if fs.exists(copied_seed) and fs.remove_file(copied_seed) != 0:
        return issue61_fail(ctx, "could not remove copied seed from repo fixture")
    if fs.symlink("lib", build_project_join(repo_copy, "lib")) != 0:
        return issue61_fail(ctx, "could not link lib into repo fixture")

    let copy_err = build_copy_generated_compiler_modules(fs, repo_copy)
    if copy_err.len() > 0:
        return issue61_fail(ctx, copy_err)

    let sema_path = build_project_join(repo_copy, "src/SemaCheck.w")
    let sema_text = fs.read_text(sema_path)
    // Find the marker line and copy ITS leading whitespace for the injected
    // local: a fixed-indent splice rots when the surrounding code nests
    // deeper (the 4-space injection dedented out of the enclosing block and
    // the canary spent months red on a parse error instead of its real job).
    let marker_comment = "// Check all arguments (with expected-type propagation for Atomic ordering params)"
    let marker_at = sema_text.find(marker_comment)
    if marker_at < 0:
        return issue61_fail(ctx, "missing insertion point in " ++ sema_path)
    var indent_start = marker_at
    while indent_start > 0 and sema_text.byte_at((indent_start - 1) as i64) != 10:
        indent_start = indent_start - 1
    let indent = sema_text.slice(indent_start as i64, marker_at as i64)
    let marker = indent ++ marker_comment
    let replacement = marker ++ "\n" ++ indent ++ "var mc_issue61_padding_local: i32 = 0"
    let patched = build_replace_once(sema_text, marker, replacement)
    if patched.len() == 0:
        return issue61_fail(ctx, "missing insertion point in " ++ sema_path)
    if fs.write_text(sema_path, patched) != 0:
        return issue61_fail(ctx, "could not patch " ++ sema_path)
    if not fs.read_text(sema_path).contains("mc_issue61_padding_local"):
        return issue61_fail(ctx, "failed to inject noop local")

    let stdout_path = build_project_abs(root, build_project_join(output_dir, "check.stdout"))
    let stderr_path = build_project_abs(root, build_project_join(output_dir, "check.stderr"))
    var check_args: Vec[str] = Vec.new()
    check_args |> push(compiler_path)
    check_args |> push("check")
    check_args |> push("src/main.w")
    let check = ctx.process_runner().run_capture_cwd(check_args, stdout_path, stderr_path, 180000, build_project_abs(root, repo_copy))
    if check.rc == 124:
        return issue61_fail(ctx, "check timed out; stdout=" ++ stdout_path ++ " stderr=" ++ stderr_path)
    if check.rc != 0:
        return issue61_fail(ctx, f"check failed with exit code {check.rc}; stdout=" ++ stdout_path ++ " stderr=" ++ stderr_path)
    let output = build_trim_trailing_line_endings(check.stdout)
    if output != "ok":
        return issue61_fail(ctx, "check produced unexpected output: " ++ output)
    0

// Benign-edit invariance: the compiler's verdict on its own tree must be
// invariant under meaning-preserving perturbations (a comment, a fresh
// local, a fresh top-level let, at any position). Every #660-class defect
// — untagged unions probed by content, silent id-alignment sensitivity —
// breaks exactly this property, so this harness catches the CLASS without
// knowing the instance. Variants are a fixed deterministic list; each is
// applied to a pristine repo copy and `check src/main.w` must still say ok.
fn invariance_fail(ctx: &ActionCtx, message: &str) -> i32:
    ctx.diagnostics().error("invariance-check: " ++ message)
    1

fn invariance_run_check(ctx: &ActionCtx, compiler_path: &str, repo_copy: &str, label: &str) -> i32:
    let root = ctx.project_info().project_root()
    let stdout_path = build_project_abs(root, build_project_join(ctx.output(), label ++ ".stdout"))
    let stderr_path = build_project_abs(root, build_project_join(ctx.output(), label ++ ".stderr"))
    var check_args: Vec[str] = Vec.new()
    check_args |> push(build_owned_text(compiler_path))
    check_args |> push("check")
    check_args |> push("src/main.w")
    let check = ctx.process_runner().run_capture_cwd(check_args, stdout_path, stderr_path, 240000, build_project_abs(root, repo_copy))
    if check.rc != 0:
        return invariance_fail(ctx, f"variant '{label}' changed the verdict (exit {check.rc}); the perturbed tree is left at " ++ repo_copy ++ " — stderr=" ++ stderr_path)
    if build_trim_trailing_line_endings(check.stdout) != "ok":
        return invariance_fail(ctx, "variant '" ++ label ++ "' produced unexpected output; stdout=" ++ stdout_path)
    0

// One variant per target so the allow_parallel pool overlaps the five
// ~93s checks (was one serial 468s action). Coverage is identical: same
// variants, same check, each against its own pristine repo copy.
fn invariance_variant_action(ctx: ActionCtx) -> i32:
    let args = ctx.args()
    if args.len() == 0:
        return invariance_fail(ctx, "missing variant label argument")
    let label = args.get(0)
    var file = ""
    var payload = ""
    if label == "comment-sema":
        // Comment appended mid-merge (byte shift, no tokens).
        file = "src/Sema.w"
        payload = "\n// invariance probe comment\n"
    if label == "let-sema":
        // Fresh top-level let mid-merge (the #660 killer shape: one new
        // interned symbol shifts every later-first-seen symbol id).
        file = "src/Sema.w"
        payload = "\nlet __INVARIANCE_PAD_A: i32 = 0\n"
    if label == "two-lets-sema":
        // Two fresh lets (larger id shift).
        file = "src/Sema.w"
        payload = "\nlet __INVARIANCE_PAD_B: i32 = 0\nlet __INVARIANCE_PAD_C: i32 = 0\n"
    if label == "let-parser":
        // Fresh let in a different merge position.
        file = "src/Parser.w"
        payload = "\nlet __INVARIANCE_PAD_D: i32 = 0\n"
    if label == "let-main":
        // Fresh let in the root module (parsed first, ids lowest).
        file = "src/main.w"
        payload = "\nlet __INVARIANCE_PAD_E: i32 = 0\n"
    if file.len() == 0:
        return invariance_fail(ctx, "unknown variant label: " ++ label)
    let inputs = ctx.inputs()
    if inputs.len() == 0:
        return invariance_fail(ctx, "missing compiler input")
    let fs = ctx.fs()
    let output_dir = ctx.output()
    if fs.mkdir_all(output_dir) != 0:
        return invariance_fail(ctx, "could not create output directory: " ++ output_dir)
    if os() == "Windows":
        print("invariance-check: skipped on Windows (#811)")
        let _ = fs.write_text(build_project_join(output_dir, ".stamp"), "ok")
        return 0
    let root = ctx.project_info().project_root()
    let compiler_path = build_project_abs(root, inputs.get(0))
    if not fs.exists(inputs.get(0)):
        return invariance_fail(ctx, "missing compiler: " ++ inputs.get(0))

    let repo_copy = build_project_join(output_dir, "repo")
    if fs.exists(repo_copy) and fs.remove_tree(repo_copy) != 0:
        return invariance_fail(ctx, "could not remove existing repo copy: " ++ repo_copy)
    if fs.mkdir_all(repo_copy) != 0:
        return invariance_fail(ctx, "could not create repo copy directory: " ++ repo_copy)
    if fs.copy_tree("src", build_project_join(repo_copy, "src")) != 0:
        return invariance_fail(ctx, "could not copy src into repo fixture")
    let copied_seed = build_project_join(repo_copy, "src/main")
    if fs.exists(copied_seed) and fs.remove_file(copied_seed) != 0:
        return invariance_fail(ctx, "could not remove copied seed from repo fixture")
    if fs.symlink("lib", build_project_join(repo_copy, "lib")) != 0:
        return invariance_fail(ctx, "could not link lib into repo fixture")
    let copy_err = build_copy_generated_compiler_modules(fs, repo_copy)
    if copy_err.len() > 0:
        return invariance_fail(ctx, copy_err)

    let edit_copy = build_project_join(repo_copy, file)
    let pristine = fs.read_text(edit_copy)
    if pristine.len() == 0:
        return invariance_fail(ctx, "could not read pristine source: " ++ edit_copy)
    if fs.write_text(edit_copy, pristine ++ payload) != 0:
        return invariance_fail(ctx, "could not write variant " ++ label)
    invariance_run_check(ctx, compiler_path, repo_copy, label)

// Debug-allocator fixture lane: build tools/debug_drop.w, then run it in `check`
// mode over test/debug_alloc/*.w. Gives the floor eyes for the over/under-drop
// blind spot it is structurally unable to see. See docs/debug-allocator.md.
fn run_debug_alloc_tests_action(ctx: ActionCtx) -> i32:
    let inputs = ctx.inputs()
    if inputs.len() == 0:
        ctx.diagnostics().error("debug-alloc-tests: missing compiler input")
        return 1
    let fs = ctx.fs()
    let out_dir = ctx.output()
    if fs.mkdir_all(out_dir) != 0:
        ctx.diagnostics().error("debug-alloc-tests: could not create output dir: " ++ out_dir)
        return 1
    // #807: the debug-alloc lane is non-functional on Windows — every fixture
    // exits 1 under --debug-alloc (uniform, not per-test logic). Gate the whole
    // lane off on Windows until the port is root-caused; Linux/macOS stay active.
    if os() == "Windows":
        print("debug-alloc-tests: skipped on Windows (#807)")
        let _ = fs.write_text(build_project_join(out_dir, ".stamp"), "ok")
        return 0
    let root = ctx.project_info().project_root()
    let compiler = build_project_abs(root, inputs.get(0))
    let driver_bin = build_project_abs(root, build_project_join(out_dir, "debug_drop"))

    var build_args: Vec[str] = Vec.new()
    build_args.push(build_owned_text(compiler))
    build_args.push("build")
    build_args.push("tools/debug_drop.w")
    build_args.push("-o")
    build_args.push(build_owned_text(driver_bin))
    let bout = build_project_abs(root, build_project_join(out_dir, "build.stdout"))
    let berr = build_project_abs(root, build_project_join(out_dir, "build.stderr"))
    let br = ctx.process_runner().run_capture_cwd(build_args, bout, berr, 180000, root)
    if br.rc != 0:
        ctx.diagnostics().error(f"debug-alloc-tests: driver build failed rc={br.rc}; stderr={berr}")
        return 1

    let fixtures = fs.list_files("test/debug_alloc")
    var check_args: Vec[str] = Vec.new()
    check_args.push(driver_bin)
    check_args.push("check")
    check_args.push(compiler)
    for i in 0..fixtures.len() as i32:
        let p = fixtures.get(i as i64)
        if p.ends_with(".w"):
            check_args.push(build_project_abs(root, p))
    let cout = build_project_abs(root, build_project_join(out_dir, "check.stdout"))
    let cerr = build_project_abs(root, build_project_join(out_dir, "check.stderr"))
    let cr = ctx.process_runner().run_capture_cwd(check_args, cout, cerr, 240000, root)
    if cr.rc != 0:
        ctx.diagnostics().error(f"debug-alloc-tests: lane failed rc={cr.rc}\n" ++ cr.stdout)
        return 1
    let _ = fs.write_text(build_project_join(out_dir, ".stamp"), "ok")
    0

// Drop-exactly-once audit matrix (tools/drop_audit.w — the repo-committed
// successor to the lost drop-audit skill). Candidate = the freshly built
// release compiler; baseline = the last-green-verified seed (src/main), so
// drop-scheduling regressions self-identify as verdict differences. Run
// BEFORE and AFTER any change to drop scheduling, ownership lowering, or
// receiver modes (CLAUDE.md gate): `with build :drop-audit`.
fn run_drop_audit_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let out_dir = ctx.output()
    if fs.mkdir_all(out_dir) != 0:
        ctx.diagnostics().error("drop-audit: could not create output dir: " ++ out_dir)
        return 1
    let root = ctx.project_info().project_root()
    let candidate = build_project_abs(root, ctx.inputs().get(0))
    let baseline = build_project_abs(root, "src/main")
    var args: Vec[str] = Vec.new()
    args.push(build_owned_text(candidate))
    args.push("run")
    args.push("tools/drop_audit.w")
    args.push(build_owned_text(candidate))
    args.push(baseline)
    // read_text/write_text require a project-relative path (the capability
    // sandbox rejects absolute paths); run_capture_cwd takes the absolute form.
    let aout_rel = build_project_join(out_dir, "audit.stdout")
    let aout = build_project_abs(root, aout_rel)
    let aerr = build_project_abs(root, build_project_join(out_dir, "audit.stderr"))
    let ar = ctx.process_runner().run_capture_cwd(args, aout, aerr, 600000, root)
    let report = fs.read_text(aout_rel)
    if ar.rc != 0:
        ctx.diagnostics().error(f"drop-audit: regressions vs baseline (rc={ar.rc})\n" ++ report)
        return 1
    let _ = fs.write_text(build_project_join(out_dir, ".stamp"), "ok")
    let _ = report
    0

// Move-checker verdict matrix (tools/move_audit.w — the compile-time analog of
// drop-audit). Candidate = the freshly built release compiler; each cell has a
// ground-truth expected verdict, so a drifted dataflow transfer function (the
// #696 class: per-edge move checks that encode the rule differently) fails its
// cell. The gate keys on vs-EXPECTED failures (rc), so it holds across reseeds;
// the baseline (src/main) column just shows what moved. Run BEFORE and AFTER any
// change to move/borrow checking, branch-merge, loop back-edge handling, or
// type_needs_drop (CLAUDE.md gate): `with build :move-audit`.
fn run_move_audit_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let out_dir = ctx.output()
    if fs.mkdir_all(out_dir) != 0:
        ctx.diagnostics().error("move-audit: could not create output dir: " ++ out_dir)
        return 1
    let root = ctx.project_info().project_root()
    let candidate = build_project_abs(root, ctx.inputs().get(0))
    let baseline = build_project_abs(root, "src/main")
    var args: Vec[str] = Vec.new()
    args.push(build_owned_text(candidate))
    args.push("run")
    args.push("tools/move_audit.w")
    args.push(candidate)
    args.push(baseline)
    // read_text/write_text require a project-relative path (the capability
    // sandbox rejects absolute paths); run_capture_cwd takes the absolute form.
    let aout_rel = build_project_join(out_dir, "audit.stdout")
    let aout = build_project_abs(root, aout_rel)
    let aerr = build_project_abs(root, build_project_join(out_dir, "audit.stderr"))
    let ar = ctx.process_runner().run_capture_cwd(args, aout, aerr, 600000, root)
    let report = fs.read_text(aout_rel)
    if ar.rc != 0:
        ctx.diagnostics().error(f"move-audit: cells disagree with ground truth (rc={ar.rc})\n" ++ report)
        return 1
    let _ = fs.write_text(build_project_join(out_dir, ".stamp"), "ok")
    let _ = report
    0

fn run_fixpoint_diff_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let output = ctx.output()
    let out_dir = build_project_dirname(output)
    if fs.mkdir_all(out_dir) != 0:
        ctx.diagnostics().error("fixpoint-diff: could not create output dir: " ++ out_dir)
        return 1
    let root = ctx.project_info().project_root()
    let compiler = build_project_abs(root, stage_compiler_bin("with-stage2"))
    let left = build_project_abs(root, stage_compiler_obj("with-stage2-fixpoint.o"))
    let right = build_project_abs(root, stage_compiler_obj("with-stage3-fixpoint.o"))
    let err_path = build_project_abs(root, build_project_join(out_dir, "stderr.txt"))
    var args: Vec[str] = Vec.new()
    args.push(compiler)
    args.push("fixpoint-diff")
    args.push(left)
    args.push(right)
    let result = ctx.process_runner().run_capture_cwd(args, build_project_abs(root, output), err_path, 120000, root)
    if result.rc != 0:
        ctx.diagnostics().error("fixpoint-diff: report command failed; stderr=" ++ err_path)
        return result.rc
    0

fn deep_debug_tool_expect(ctx: &ActionCtx, root: &str, compiler: &str, source_path: &str, out_dir: &str, name: &str, opt_a: &str, opt_b: &str, needle: &str) -> i32:
    var args: Vec[str] = Vec.new()
    args.push(build_owned_text(compiler))
    args.push("check")
    if opt_a.len() > 0:
        args.push(build_owned_text(opt_a))
    if opt_b.len() > 0:
        args.push(build_owned_text(opt_b))
    args.push(build_owned_text(source_path))

    let stdout_rel = build_project_join(out_dir, name ++ ".stdout")
    let stderr_rel = build_project_join(out_dir, name ++ ".stderr")
    let stdout_path = build_project_abs(root, stdout_rel)
    let stderr_path = build_project_abs(root, stderr_rel)
    let result = ctx.process_runner().run_capture_cwd(args, stdout_path, stderr_path, 120000, root)
    if result.rc != 0:
        ctx.diagnostics().error(f"deep-debug-tool-tests: {name} failed rc={result.rc}; stdout={stdout_path} stderr={stderr_path}")
        return result.rc
    if not ctx.fs().read_text(stdout_rel).contains(needle):
        ctx.diagnostics().error("deep-debug-tool-tests: " ++ name ++ " report missing '" ++ needle ++ "'; stdout=" ++ stdout_path)
        return 1
    0

fn deep_debug_analyze_expect(ctx: &ActionCtx, root: &str, compiler: &str, source_path: &str, out_dir: &str, name: &str, request: &str, needle: &str) -> i32:
    let args: Vec[str] = Vec.new()
    args.push(build_owned_text(compiler))
    args.push("analyze")
    args.push(build_owned_text(source_path))
    args.push(build_owned_text(request))
    let stdout_rel = build_project_join(out_dir, name ++ ".stdout")
    let stderr_rel = build_project_join(out_dir, name ++ ".stderr")
    let stdout_path = build_project_abs(root, stdout_rel)
    let stderr_path = build_project_abs(root, stderr_rel)
    let result = ctx.process_runner().run_capture_cwd(args, stdout_path, stderr_path, 120000, root)
    if result.rc != 0:
        ctx.diagnostics().error(f"deep-debug-tool-tests: {name} failed rc={result.rc}; stdout={stdout_path} stderr={stderr_path}")
        return result.rc
    if not ctx.fs().read_text(stdout_rel).contains(needle):
        ctx.diagnostics().error("deep-debug-tool-tests: " ++ name ++ " report missing '" ++ needle ++ "'; stdout=" ++ stdout_path)
        return 1
    0

fn run_deep_debug_tool_tests_action(ctx: ActionCtx) -> i32:
    let inputs = ctx.inputs()
    if inputs.len() == 0:
        ctx.diagnostics().error("deep-debug-tool-tests: missing compiler input")
        return 1
    let fs = ctx.fs()
    let out_dir = ctx.output()
    if fs.mkdir_all(out_dir) != 0:
        ctx.diagnostics().error("deep-debug-tool-tests: could not create output dir: " ++ out_dir)
        return 1
    let root = ctx.project_info().project_root()
    let compiler = build_project_abs(root, inputs.get(0))
    let reduce_input = build_project_join(out_dir, "reduce-input.w")
    let reduce_output = build_project_join(out_dir, "reduce-output.w")
    let reduce_source =
        "fn unused:\n" ++
        "    let ok = 1\n" ++
        "    let _ = ok\n\n" ++
        "fn main:\n" ++
        "    missing_symbol\n"
    if fs.write_text(reduce_input, reduce_source) != 0:
        ctx.diagnostics().error("deep-debug-tool-tests: could not write reducer fixture")
        return 1
    var reduce_args: Vec[str] = Vec.new()
    reduce_args.push(build_owned_text(compiler))
    reduce_args.push("reduce")
    reduce_args.push(build_project_abs(root, reduce_input))
    reduce_args.push("--out")
    reduce_args.push(build_project_abs(root, reduce_output))
    reduce_args.push("--contains")
    reduce_args.push("undefined variable")
    reduce_args.push("--")
    reduce_args.push(build_owned_text(compiler))
    reduce_args.push("check")
    reduce_args.push("{file}")
    let reduce_stdout = build_project_abs(root, build_project_join(out_dir, "reduce.stdout"))
    let reduce_stderr = build_project_abs(root, build_project_join(out_dir, "reduce.stderr"))
    let reduce_result = ctx.process_runner().run_capture_cwd(reduce_args, reduce_stdout, reduce_stderr, 120000, root)
    if reduce_result.rc != 0:
        ctx.diagnostics().error("deep-debug-tool-tests: reduce failed; stderr=" ++ reduce_stderr)
        return reduce_result.rc
    let reduced_text = fs.read_text(reduce_output)
    if not reduced_text.contains("missing_symbol"):
        ctx.diagnostics().error("deep-debug-tool-tests: reducer output lost predicate line")
        return 1

    let left = build_project_join(out_dir, "left.bin")
    let right = build_project_join(out_dir, "right.bin")
    let report = build_project_join(out_dir, "fixpoint-diff.txt")
    if fs.write_text(left, "abc") != 0 or fs.write_text(right, "abd") != 0:
        ctx.diagnostics().error("deep-debug-tool-tests: could not write diff fixtures")
        return 1
    var diff_args: Vec[str] = Vec.new()
    diff_args.push(build_owned_text(compiler))
    diff_args.push("fixpoint-diff")
    diff_args.push(build_project_abs(root, left))
    diff_args.push(build_project_abs(root, right))
    let diff_stderr = build_project_abs(root, build_project_join(out_dir, "fixpoint-diff.stderr"))
    let diff_result = ctx.process_runner().run_capture_cwd(diff_args, build_project_abs(root, report), diff_stderr, 120000, root)
    if diff_result.rc != 0:
        ctx.diagnostics().error("deep-debug-tool-tests: fixpoint-diff failed; stderr=" ++ diff_stderr)
        return diff_result.rc
    if not fs.read_text(report).contains("first-different-offset"):
        ctx.diagnostics().error("deep-debug-tool-tests: fixpoint-diff report missing offset")
        return 1

    let ownership_input = build_project_join(out_dir, "ownership-input.w")
    let ownership_source =
        "type Resource { id: i32 }\n\n" ++
        "type Plain { id: i32 }\n\n" ++
        "type Matrix { n: i32 }\n\n" ++
        "impl Matrix:\n" ++
        "    mut fn write(): self.n = self.n + 1\n" ++
        "    mut fn transitive_write(): self.write()\n" ++
        "    move fn take() -> Matrix: self\n\n" ++
        "impl Drop for Resource:\n" ++
        "    move fn drop():\n" ++
        "        let _ = self.id\n\n" ++
        "fn consume(r: Resource):\n" ++
        "    let _ = r.id\n\n" ++
        "fn choose(flag: bool):\n" ++
        "    if flag:\n" ++
        "        let x = 1\n" ++
        "        let _ = x\n" ++
        "    else:\n" ++
        "        let y = 2\n" ++
        "        let _ = y\n\n" ++
        "fn main:\n" ++
        "    let p = Plain { id: 3 }\n" ++
        "    let value = p.id\n" ++
        "    let _ = value\n" ++
        "    let r = Resource { id: 7 }\n" ++
        "    consume(r)\n" ++
        "    choose(true)\n"
    if fs.write_text(ownership_input, ownership_source) != 0:
        ctx.diagnostics().error("deep-debug-tool-tests: could not write ownership fixture")
        return 1
    let ownership_abs = build_project_abs(root, ownership_input)
    if deep_debug_tool_expect(ctx, root, compiler, ownership_abs, out_dir, "trace-ownership", "--trace-ownership", "main:", "event=") != 0:
        return 1
    if deep_debug_tool_expect(ctx, root, compiler, ownership_abs, out_dir, "dump-drop-plan", "--dump-drop-plan", "", "drop-plan module") != 0:
        return 1
    if deep_debug_tool_expect(ctx, root, compiler, ownership_abs, out_dir, "validate-ownership", "--validate-ownership", "", "validate-ownership: ok") != 0:
        return 1
    if deep_debug_tool_expect(ctx, root, compiler, ownership_abs, out_dir, "dump-place-map", "--dump-place-map", "", "projections=[Field") != 0:
        return 1
    if deep_debug_tool_expect(ctx, root, compiler, ownership_abs, out_dir, "trace-cleanup-edge", "--trace-cleanup-edge", "choose:bb0->bb1", "edge=bb0->bb1") != 0:
        return 1
    if deep_debug_analyze_expect(ctx, root, compiler, ownership_abs, out_dir, "analyze-audit", "audit:all", "compiler-analysis-audit") != 0:
        return 1
    if deep_debug_analyze_expect(ctx, root, compiler, ownership_abs, out_dir, "analyze-storage", "audit:storage", "storage-audit") != 0:
        return 1
    // #927: a move-self builder that rebinds `self` and then builds an
    // aggregate must audit clean — the use-after-kill validator once read an
    // aggregate's kind slot as an operand and flagged the moved `self`.
    let rebind_input = build_project_join(out_dir, "rebind-input.w")
    let rebind_source =
        "type Pair { a: i32, b: i32 }\n\n" ++
        "type P { vars: Vec[i32] }\n\n" ++
        "pub fn P.set(move self: Self, v: i32) -> P:\n" ++
        "    var owned = self\n" ++
        "    let pair = Pair { a: v, b: v }\n" ++
        "    owned.vars.push(pair.a)\n" ++
        "    owned\n\n" ++
        "fn main:\n" ++
        "    var p = P { vars: Vec.new() }\n" ++
        "    p = p.set(1)\n" ++
        "    print(f\"{p.vars.len()}\")\n"
    if fs.write_text(rebind_input, rebind_source) != 0:
        ctx.diagnostics().error("deep-debug-tool-tests: could not write rebind fixture")
        return 1
    if deep_debug_analyze_expect(ctx, root, compiler, build_project_abs(root, rebind_input), out_dir, "analyze-audit-rebind", "audit:all", "violations=0 ok") != 0:
        return 1
    // D5 superseded: a read-only free parameter is owned, not share-place —
    // callee-place-alias marshalling survives only on receivers (D12), so the
    // matrix probe targets the mut-receiver method.
    if deep_debug_analyze_expect(ctx, root, compiler, ownership_abs, out_dir, "analyze-matrix", "matrix:name~Matrix.write", "callee-place-alias") != 0:
        return 1
    if deep_debug_analyze_expect(ctx, root, compiler, ownership_abs, out_dir, "analyze-receiver-effects", "matrix:kind=receiver,name~Matrix.transitive_write", "declared=mut required=mut") != 0:
        return 1
    if deep_debug_analyze_expect(ctx, root, compiler, ownership_abs, out_dir, "analyze-path", "path:call:main:consume", "call-path: main -> consume") != 0:
        return 1
    // #727: the D7 self-less surface gate, re-armed. The audit conforms to
    // the trait read carve-out; a new explicit receiver anywhere else in
    // this unit is a red lane, not a note.
    if deep_debug_analyze_expect(ctx, root, compiler, ownership_abs, out_dir, "analyze-receiver-surface", "audit:receiver-surface", "receiver-surface-audit: facts=") != 0:
        return 1
    let _ = fs.write_text(build_project_join(out_dir, ".stamp"), "ok")
    0

pub fn build(ctx: BuildCtx) -> Build:
    var out = ctx.new_build()
    let host_runtime = host_runtime_spec()
    let release_version = build_project_trim_line(ctx.fs().read_text("src/version"))

    // Keep the stage chain's generated main source independent of commit
    // identity. If a HEAD-sensitive generator were its dependency, the cache's
    // `dependency rebuilt` rule would force stage1 after every commit even when
    // out/gen/main.w stayed byte-identical (#650).
    var compiler_main_source = target_new(.Action, "compiler-main-source", "").output("out/gen/.main-generated-stamp")
    compiler_main_source.action = run_generate_compiler_main_source_action
    compiler_main_source = compiler_main_source.input("src/main.w")
    compiler_main_source = compiler_main_source.extra_output("out/gen/main.w")
    out = out.add_target(compiler_main_source)

    // Emit-C/bootstrap/version artifacts retain their exact version
    // substitution, but live behind a separate target so their HEAD dependency
    // cannot invalidate the native compiler stage chain.
    var compiler_version_sources = target_new(.Action, "compiler-version-sources", "").output("out/gen/.generated-stamp")
    compiler_version_sources.action = run_generate_compiler_version_sources_action
    compiler_version_sources = compiler_version_sources.input("src/main.w")
    compiler_version_sources = compiler_version_sources.input("src/bootstrap_main.w")
    compiler_version_sources = compiler_version_sources.input("src/version")
    compiler_version_sources = compiler_version_sources.extra_output("out/gen/versioned_main.w")
    compiler_version_sources = compiler_version_sources.extra_output("out/gen/bootstrap_main.w")
    compiler_version_sources = compiler_version_sources.extra_output("out/gen/version.txt")
    compiler_version_sources = target_with_version_inputs(move compiler_version_sources, ctx)
    out = out.add_target(compiler_version_sources)

    var compiler_sources = target_new(.Group, "compiler-sources", "")
    compiler_sources = compiler_sources.dep("compiler-main-source")
    compiler_sources = compiler_sources.dep("compiler-version-sources")
    out = out.add_target(compiler_sources)

    var print_version = target_new(.Action, "print-version", "").output("out/.build-state/print-version.txt")
    print_version.action = run_print_version_action
    print_version = print_version.input("src/version")
    print_version = target_with_version_inputs(move print_version, ctx)
    out = out.add_target(print_version)

    var bootstrap_c_emit_sources = target_new(.Action, "bootstrap-c-emit-sources", "").output("out/bootstrap-c/src/with_compiler.c")
    bootstrap_c_emit_sources.action = run_bootstrap_c_emit_sources_action
    bootstrap_c_emit_sources = bootstrap_c_emit_sources.extra_output("out/gen/wl_decls.h")
    bootstrap_c_emit_sources = bootstrap_c_emit_sources.extra_output("out/gen/wl_stubs.c")
    bootstrap_c_emit_sources = bootstrap_c_emit_sources.write_scope("out/bootstrap-c/src")
    bootstrap_c_emit_sources = bootstrap_c_emit_sources.write_scope("out/gen")
    bootstrap_c_emit_sources = bootstrap_c_emit_sources.write_scope("out/command/bootstrap-c-emit-sources")
    bootstrap_c_emit_sources = bootstrap_c_emit_sources.input("out/gen/versioned_main.w")
    bootstrap_c_emit_sources = bootstrap_c_emit_sources.dep("compiler-version-sources")
    // The compiler source imports the generated EmbeddedStdlibData and
    // EmbeddedClangResourceData modules (same as stage1/2/3); without these
    // deps a standalone `:bootstrap-c-emit-sources` on a clean tree fails
    // with "import module not found".
    bootstrap_c_emit_sources = bootstrap_c_emit_sources.dep("compat-runtime-source")
    bootstrap_c_emit_sources = bootstrap_c_emit_sources.dep("embedded-clang-resource-source")
    out = out.add_target(bootstrap_c_emit_sources)

    var package_bootstrap_c = target_new(.Action, "package-bootstrap-c", "").output("out/release/with-bootstrap-c-" ++ release_version ++ ".tar.gz")
    package_bootstrap_c.action = run_package_bootstrap_c_action
    package_bootstrap_c = package_bootstrap_c.arg(release_compiler_bin("with"))
    package_bootstrap_c = target_with_version_inputs(move package_bootstrap_c, ctx)
    package_bootstrap_c = package_bootstrap_c.dep("build")
    package_bootstrap_c = package_bootstrap_c.dep("bootstrap-c-emit-sources")
    package_bootstrap_c = package_bootstrap_c.input("src/version")
    package_bootstrap_c = package_bootstrap_c.input("out/release/bin/with")
    package_bootstrap_c = package_bootstrap_c.input("out/bootstrap-c/src/with_compiler.c")
    package_bootstrap_c = package_bootstrap_c.input("out/gen/wl_decls.h")
    package_bootstrap_c = package_bootstrap_c.input("rt/rt_core.w")
    package_bootstrap_c = package_bootstrap_c.input("rt/panic_runtime.w")
    package_bootstrap_c = package_bootstrap_c.input("rt/regex_runtime.w")
    package_bootstrap_c = package_bootstrap_c.input("rt/fiber_stubs.w")
    package_bootstrap_c = package_bootstrap_c.input("rt/compat_runtime.w")
    package_bootstrap_c = package_bootstrap_c.input("runtime/with_runtime.h")
    package_bootstrap_c = package_bootstrap_c.input("runtime/unistd.h")
    package_bootstrap_c = package_bootstrap_c.input("runtime/undef_stdio_macros.h")
    package_bootstrap_c = package_bootstrap_c.input("runtime/sys/resource.h")
    package_bootstrap_c = package_bootstrap_c.input("scripts/bootstrap/linux_platform.c")
    package_bootstrap_c = package_bootstrap_c.input("scripts/bootstrap/windows_platform.c")
    package_bootstrap_c = package_bootstrap_c.input("scripts/bootstrap/windows_compat_runtime.c")
    package_bootstrap_c = package_bootstrap_c.input("scripts/bootstrap/empty_embedded_windows.s")
    package_bootstrap_c = package_bootstrap_c.input("build/package.w")
    package_bootstrap_c = package_bootstrap_c.input("build/zlib_gzip.w")
    package_bootstrap_c = package_bootstrap_c.write_scope("out/bootstrap-c-package")
    package_bootstrap_c = package_bootstrap_c.write_scope("out/release")
    package_bootstrap_c = package_bootstrap_c.write_scope("out/command/package-bootstrap-c")
    package_bootstrap_c = package_bootstrap_c.timeout(900000)
    out = out.add_target(package_bootstrap_c)

    out = out.add_target(package_platform_target("package-darwin-aarch64", "darwin-aarch64", ctx))
    out = out.add_target(package_platform_target("package-linux-x86_64", "linux-x86_64", ctx))
    out = out.add_target(package_platform_target("package-windows-x86_64", "windows-x86_64", ctx))
    out = out.add_target(package_platform_target("package-windows-aarch64", "windows-aarch64", ctx))
    out = out.add_target(package_current_host_target())
    out = out.add_target(package_llvm_sdk_platform_target("package-llvm-sdk-darwin-aarch64", "darwin-aarch64", sdk_default_prefix_for_platform("darwin-aarch64"), sdk_default_build_cache_for_platform("darwin-aarch64")))
    out = out.add_target(package_llvm_sdk_platform_target("package-llvm-sdk-linux-x86_64", "linux-x86_64", sdk_default_prefix_for_platform("linux-x86_64"), sdk_default_build_cache_for_platform("linux-x86_64")))
    out = out.add_target(package_llvm_sdk_platform_target("package-llvm-sdk-linux-aarch64", "linux-aarch64", sdk_default_prefix_for_platform("linux-aarch64"), sdk_default_build_cache_for_platform("linux-aarch64")))
    out = out.add_target(package_llvm_sdk_platform_target("package-llvm-sdk-windows-x86_64", "windows-x86_64", sdk_default_prefix_for_platform("windows-x86_64"), sdk_default_build_cache_for_platform("windows-x86_64")))
    out = out.add_target(package_llvm_sdk_platform_target("package-llvm-sdk-windows-aarch64", "windows-aarch64", sdk_default_prefix_for_platform("windows-aarch64"), sdk_default_build_cache_for_platform("windows-aarch64")))
    out = out.add_target(package_llvm_sdk_current_host_target())

    out = out.add_target(sdk_source_target("sdk-ninja-source", sdk_ninja_source_url(), sdk_ninja_source_sha256(), sdk_ninja_archive(), sdk_source_root(), sdk_ninja_source_dir(), sdk_ninja_source_marker()))
    out = out.add_target(sdk_source_target("sdk-cmake-source", sdk_cmake_source_url(), sdk_cmake_source_sha256(), sdk_cmake_archive(), sdk_source_root(), sdk_cmake_source_dir(), sdk_cmake_source_marker()))
    out = out.add_target(sdk_source_target("sdk-llvm-source", sdk_llvm_source_url(), sdk_llvm_source_sha256(), sdk_llvm_archive(), sdk_source_root(), sdk_llvm_source_dir(), sdk_llvm_source_marker()))
    out = out.add_target(sdk_ninja_target(ctx))
    out = out.add_target(sdk_cmake_target(ctx))
    out = out.add_target(sdk_llvm_target(ctx))
    out = out.add_target(sdk_group_target())
    out = out.add_target(sdk_package_target(ctx))

    var compat_runtime = target_new(.Action, "compat-runtime-source", "").output("out/gen/compat_runtime.w")
    compat_runtime = compat_runtime.extra_output("out/gen/compiler/EmbeddedStdlibData.w")
    compat_runtime = compat_runtime.extra_output("out/gen/compiler/EmbeddedRuntimeData.w")
    // D38: the embedded .wo bundle index (empty until the first bundle; each
    // embedded bundle is named as an arg here and carried as blobs by the
    // embedded-objects target).
    compat_runtime = compat_runtime.extra_output("out/gen/compiler/EmbeddedBundlesData.w")
    compat_runtime = compat_runtime.input(build_owned_text(host_runtime.compat_source))
    compat_runtime = target_with_embedded_stdlib_inputs(move compat_runtime, ctx)
    compat_runtime = target_with_embedded_runtime_inputs(move compat_runtime, ctx)
    compat_runtime.action = generate_compat_runtime_action
    out = out.add_target(compat_runtime)

    // Embed clang's builtin headers into the binary so c_import is self-contained
    // at runtime (#312). Generated from the static SDK fetched/built into .deps.
    var clang_resource = target_new(.Action, "embedded-clang-resource-source", "").output("out/gen/compiler/EmbeddedClangResourceData.w")
    clang_resource.action = generate_embedded_clang_resource_action
    out = out.add_target(clang_resource)

    var compiler_no_c_export = target_new(.Action, "compiler-no-c-export", "").output("out/.build-state/compiler-no-c-export.txt")
    compiler_no_c_export.action = run_check_compiler_no_new_c_export_action
    compiler_no_c_export = compiler_no_c_export.write_scope("out/.build-state")
    compiler_no_c_export = target_with_compiler_c_export_audit_inputs(move compiler_no_c_export, ctx)
    out = out.add_target(compiler_no_c_export)

    var requirements_informative = target_new(.Action, "requirements-informative-check", "").output("out/.build-state/requirements-informative-check.txt")
    requirements_informative.action = run_check_requirements_informative_action
    requirements_informative = requirements_informative.write_scope("out/.build-state")
    requirements_informative = requirements_informative.input("docs/requirements.md")
    out = out.add_target(requirements_informative)

    // docs/requirements.md is hand-maintained, NOT build-generated. The former
    // `requirements` (generate) and `requirements-check` targets — which rewrote
    // docs/requirements.md from the spec and failed the build if it differed —
    // have been removed (build/requirements.w deleted). The build must never
    // auto-generate or auto-modify docs/requirements.md.

    var spec_inventory = target_new(.Action, "spec-inventory-check", "").output("out/.build-state/spec-inventory-check.txt")
    spec_inventory.action = run_check_spec_inventory_action
    spec_inventory = spec_inventory.write_scope("out/.build-state")
    spec_inventory = spec_inventory.input("docs/with-specification.md")
    spec_inventory = spec_inventory.input("src/Token.w")
    spec_inventory = spec_inventory.input("src/Parser.w")
    spec_inventory = spec_inventory.input("src/main.w")
    spec_inventory = spec_inventory.input("src/compiler/DriverOptions.w")
    spec_inventory = spec_inventory.input("lib/std")
    out = out.add_target(spec_inventory)

    out = out.add_target(with_object_target("bootstrap-llvm-bridge-object", "seed", "src/compiler/LlvmBridge.w", "out/bootstrap-lib/llvm_bridge.o", "-O1", ""))
    out = out.add_target(with_object_target("bootstrap-clang-bridge-object", "seed", "src/compiler/ClangBridge.w", "out/bootstrap-lib/clang_bridge.o", "-O1", ""))

    var bootstrap_llvm_link_metadata = target_new(.Action, "bootstrap-llvm-link-metadata", "").output("out/bootstrap-lib/.llvm-link-ready")
    bootstrap_llvm_link_metadata.action = run_generate_llvm_link_metadata_action
    bootstrap_llvm_link_metadata = bootstrap_llvm_link_metadata.input("out/bootstrap-lib/llvm_bridge.o")
    bootstrap_llvm_link_metadata = bootstrap_llvm_link_metadata.input("out/bootstrap-lib/clang_bridge.o")
    bootstrap_llvm_link_metadata = bootstrap_llvm_link_metadata.extra_output("out/bootstrap-lib/llvm_link.rsp")
    bootstrap_llvm_link_metadata = bootstrap_llvm_link_metadata.extra_output("out/bootstrap-lib/llvm_cc")
    bootstrap_llvm_link_metadata = bootstrap_llvm_link_metadata.extra_output("out/bootstrap-lib/llvm_ld.rsp")
    bootstrap_llvm_link_metadata = bootstrap_llvm_link_metadata.extra_output("out/bootstrap-lib/llvm_ld")
    bootstrap_llvm_link_metadata = bootstrap_llvm_link_metadata.dep("bootstrap-llvm-bridge-object")
    bootstrap_llvm_link_metadata = bootstrap_llvm_link_metadata.dep("bootstrap-clang-bridge-object")
    out = out.add_target(bootstrap_llvm_link_metadata)

    out = out.add_target(with_object_target("bootstrap-rt-core-object", "seed", "rt/rt_core.w", "out/bootstrap-lib/rt_core.o", "-O1", ""))
    out = out.add_target(with_object_target("bootstrap-rt-platform-object", "seed", host_runtime.platform_source, host_runtime.bootstrap_platform_object, "-O1", ""))
    let bootstrap_empty_syms = embedded_platform_symbols()
    for bi in 0..bootstrap_empty_syms.len() as i32:
        let bsym = bootstrap_empty_syms.get(bi as i64)
        if bsym != host_runtime.platform_symbol:
            out = out.add_target(empty_file_target(empty_platform_blob_target("bootstrap-empty-", bsym), empty_platform_blob_path("out/bootstrap-lib", bsym)))
    out = out.add_target(with_object_target("bootstrap-cimport-stubs-object", "seed", "rt/cimport_stubs.w", "out/bootstrap-lib/cimport_stubs.o", "-O1", ""))
    out = out.add_target(with_object_target("bootstrap-compat-runtime-object", "seed", "out/gen/compat_runtime.w", "out/bootstrap-lib/compat_runtime.o", "-O1", "compat-runtime-source"))
    out = out.add_target(with_object_target("bootstrap-panic-runtime-object", "seed", "rt/panic_runtime.w", "out/bootstrap-lib/panic_runtime.o", "-O1", ""))
    out = out.add_target(with_ir_target_overflow("bootstrap-regex-runtime-ir", "seed", "rt/regex_runtime.w", "out/bootstrap-tmp/regex_runtime.ll", "", "wrap"))
    var bootstrap_regex_runtime = target_new(.CompileLlvmIrObject, "bootstrap-regex-runtime-object", "out/bootstrap-tmp/regex_runtime.ll").output("out/bootstrap-lib/regex_runtime.o")
    bootstrap_regex_runtime = bootstrap_regex_runtime.dep("bootstrap-regex-runtime-ir")
    out = out.add_target(bootstrap_regex_runtime)
    out = out.add_target(with_object_target("bootstrap-fiber-stubs-object", "seed", "rt/fiber_stubs.w", "out/bootstrap-lib/fiber_stubs.o", "-O1", ""))
    out = out.add_target(with_object_target("bootstrap-channel-runtime-object", "seed", "rt/channel_runtime.w", "out/bootstrap-lib/channel_runtime.o", "-O1", ""))
    out = out.add_target(with_object_target("bootstrap-fiber-runtime-object", "seed", "rt/fiber_runtime.w", "out/bootstrap-lib/fiber_runtime.o", "-O1", ""))
    out = out.add_target(with_object_target("bootstrap-fiber-core-object", "seed", host_runtime.fiber_core_source, "out/bootstrap-lib/fiber.o", "-O1", ""))
    var bootstrap_fiber_asm = target_new(.CompileAsmObject, "bootstrap-fiber-asm-object", build_owned_text(host_runtime.fiber_asm_source)).output("out/bootstrap-lib/fiber_asm.o")
    out = out.add_target(bootstrap_fiber_asm)

    var bootstrap_embedded_objects = target_new(.EmbedObjectFiles, "bootstrap-embedded-objects-asm", "").output("out/bootstrap-lib/embedded_objects.s")
    bootstrap_embedded_objects = bootstrap_embedded_objects.input("out/bootstrap-lib/cimport_stubs.o")
    bootstrap_embedded_objects = bootstrap_embedded_objects.arg("cimport_stubs_o")
    bootstrap_embedded_objects = bootstrap_embedded_objects.input("out/bootstrap-lib/compat_runtime.o")
    bootstrap_embedded_objects = bootstrap_embedded_objects.arg("compat_runtime_o")
    bootstrap_embedded_objects = bootstrap_embedded_objects.input("out/bootstrap-lib/panic_runtime.o")
    bootstrap_embedded_objects = bootstrap_embedded_objects.arg("panic_runtime_o")
    bootstrap_embedded_objects = bootstrap_embedded_objects.input("out/bootstrap-lib/regex_runtime.o")
    bootstrap_embedded_objects = bootstrap_embedded_objects.arg("regex_runtime_o")
    bootstrap_embedded_objects = bootstrap_embedded_objects.input("out/bootstrap-lib/fiber_stubs.o")
    bootstrap_embedded_objects = bootstrap_embedded_objects.arg("fiber_stubs_o")
    bootstrap_embedded_objects = bootstrap_embedded_objects.input("out/bootstrap-lib/channel_runtime.o")
    bootstrap_embedded_objects = bootstrap_embedded_objects.arg("channel_runtime_o")
    bootstrap_embedded_objects = bootstrap_embedded_objects.input("out/bootstrap-lib/fiber_runtime.o")
    bootstrap_embedded_objects = bootstrap_embedded_objects.arg("fiber_runtime_o")
    bootstrap_embedded_objects = bootstrap_embedded_objects.input("out/bootstrap-lib/fiber.o")
    bootstrap_embedded_objects = bootstrap_embedded_objects.arg("fiber_o")
    bootstrap_embedded_objects = bootstrap_embedded_objects.input("out/bootstrap-lib/fiber_asm.o")
    bootstrap_embedded_objects = bootstrap_embedded_objects.arg("fiber_asm_o")
    bootstrap_embedded_objects = bootstrap_embedded_objects.input("out/bootstrap-lib/rt_core.o")
    bootstrap_embedded_objects = bootstrap_embedded_objects.arg("rt_core_o")
    bootstrap_embedded_objects = bootstrap_embedded_objects.input(host_runtime.bootstrap_platform_object)
    bootstrap_embedded_objects = bootstrap_embedded_objects.arg(build_owned_text(host_runtime.platform_symbol))
    for bi2 in 0..bootstrap_empty_syms.len() as i32:
        let bsym2 = bootstrap_empty_syms.get(bi2 as i64)
        if bsym2 != host_runtime.platform_symbol:
            bootstrap_embedded_objects = bootstrap_embedded_objects.input(empty_platform_blob_path("out/bootstrap-lib", bsym2))
            bootstrap_embedded_objects = bootstrap_embedded_objects.arg(build_owned_text(bsym2))
    // Every consumed object's producer, declared (#680 edge audit).
    bootstrap_embedded_objects = bootstrap_embedded_objects.dep("bootstrap-cimport-stubs-object")
    bootstrap_embedded_objects = bootstrap_embedded_objects.dep("bootstrap-compat-runtime-object")
    bootstrap_embedded_objects = bootstrap_embedded_objects.dep("bootstrap-panic-runtime-object")
    bootstrap_embedded_objects = bootstrap_embedded_objects.dep("bootstrap-regex-runtime-object")
    bootstrap_embedded_objects = bootstrap_embedded_objects.dep("bootstrap-fiber-stubs-object")
    bootstrap_embedded_objects = bootstrap_embedded_objects.dep("bootstrap-channel-runtime-object")
    bootstrap_embedded_objects = bootstrap_embedded_objects.dep("bootstrap-fiber-runtime-object")
    bootstrap_embedded_objects = bootstrap_embedded_objects.dep("bootstrap-fiber-core-object")
    bootstrap_embedded_objects = bootstrap_embedded_objects.dep("bootstrap-fiber-asm-object")
    bootstrap_embedded_objects = bootstrap_embedded_objects.dep("bootstrap-rt-core-object")
    bootstrap_embedded_objects = bootstrap_embedded_objects.dep("bootstrap-rt-platform-object")
    for bi3 in 0..bootstrap_empty_syms.len() as i32:
        let bsym3 = bootstrap_empty_syms.get(bi3 as i64)
        if bsym3 != host_runtime.platform_symbol:
            bootstrap_embedded_objects = bootstrap_embedded_objects.dep(empty_platform_blob_target("bootstrap-empty-", bsym3))
    out = out.add_target(bootstrap_embedded_objects)
    var bootstrap_embedded_objects_obj = target_new(.CompileAsmObject, "bootstrap-embedded-objects-object", "out/bootstrap-lib/embedded_objects.s").output("out/bootstrap-lib/embedded_objects.o")
    bootstrap_embedded_objects_obj = bootstrap_embedded_objects_obj.dep("bootstrap-embedded-objects-asm")
    out = out.add_target(bootstrap_embedded_objects_obj)

    var bootstrap_runtime = target_new(.Group, "bootstrap-runtime", "")
    bootstrap_runtime = bootstrap_runtime.dep("bootstrap-llvm-link-metadata")
    bootstrap_runtime = bootstrap_runtime.dep("bootstrap-rt-core-object")
    bootstrap_runtime = bootstrap_runtime.dep("bootstrap-rt-platform-object")
    for bi4 in 0..bootstrap_empty_syms.len() as i32:
        let bsym4 = bootstrap_empty_syms.get(bi4 as i64)
        if bsym4 != host_runtime.platform_symbol:
            bootstrap_runtime = bootstrap_runtime.dep(empty_platform_blob_target("bootstrap-empty-", bsym4))
    bootstrap_runtime = bootstrap_runtime.dep("bootstrap-cimport-stubs-object")
    bootstrap_runtime = bootstrap_runtime.dep("bootstrap-compat-runtime-object")
    bootstrap_runtime = bootstrap_runtime.dep("bootstrap-panic-runtime-object")
    bootstrap_runtime = bootstrap_runtime.dep("bootstrap-regex-runtime-object")
    bootstrap_runtime = bootstrap_runtime.dep("bootstrap-fiber-stubs-object")
    bootstrap_runtime = bootstrap_runtime.dep("bootstrap-channel-runtime-object")
    bootstrap_runtime = bootstrap_runtime.dep("bootstrap-fiber-runtime-object")
    bootstrap_runtime = bootstrap_runtime.dep("bootstrap-fiber-core-object")
    bootstrap_runtime = bootstrap_runtime.dep("bootstrap-fiber-asm-object")
    bootstrap_runtime = bootstrap_runtime.dep("bootstrap-embedded-objects-object")
    out = out.add_target(bootstrap_runtime)

    var prepare_bootstrap_link_root = target_new(.Action, "prepare-bootstrap-link-root", "").output("out/bootstrap-lib/.prepared-link-root")
    prepare_bootstrap_link_root.action = run_prepare_bootstrap_link_root_action
    prepare_bootstrap_link_root = prepare_bootstrap_link_root.input("src/compiler/LlvmBridge.w")
    prepare_bootstrap_link_root = prepare_bootstrap_link_root.input("src/compiler/ClangBridge.w")
    prepare_bootstrap_link_root = prepare_bootstrap_link_root.input("rt/cimport_stubs.w")
    prepare_bootstrap_link_root = prepare_bootstrap_link_root.input("rt/rt_core.w")
    prepare_bootstrap_link_root = prepare_bootstrap_link_root.input(build_owned_text(host_runtime.platform_source))
    prepare_bootstrap_link_root = prepare_bootstrap_link_root.input(host_runtime.compat_source)
    prepare_bootstrap_link_root = prepare_bootstrap_link_root.write_scope("out/lib")
    prepare_bootstrap_link_root = prepare_bootstrap_link_root.write_scope("out/bootstrap-lib")
    prepare_bootstrap_link_root = prepare_bootstrap_link_root.dep("bootstrap-runtime")
    out = out.add_target(prepare_bootstrap_link_root)

    out = out.add_target(with_object_target("llvm-bridge-object", stage_compiler_bin("with-stage2"), "src/compiler/LlvmBridge.w", "out/lib/llvm_bridge.o", "-O1", "stage2"))
    out = out.add_target(with_object_target("clang-bridge-object", stage_compiler_bin("with-stage2"), "src/compiler/ClangBridge.w", "out/lib/clang_bridge.o", "-O1", "stage2"))

    var llvm_link_metadata = target_new(.Action, "llvm-link-metadata", "").output("out/lib/.llvm-link-ready")
    llvm_link_metadata.action = run_generate_llvm_link_metadata_action
    llvm_link_metadata = llvm_link_metadata.input("out/lib/llvm_bridge.o")
    llvm_link_metadata = llvm_link_metadata.input("out/lib/clang_bridge.o")
    llvm_link_metadata = llvm_link_metadata.extra_output("out/lib/llvm_link.rsp")
    llvm_link_metadata = llvm_link_metadata.extra_output("out/lib/llvm_cc")
    llvm_link_metadata = llvm_link_metadata.extra_output("out/lib/llvm_ld.rsp")
    llvm_link_metadata = llvm_link_metadata.extra_output("out/lib/llvm_ld")
    llvm_link_metadata = llvm_link_metadata.dep("llvm-bridge-object")
    llvm_link_metadata = llvm_link_metadata.dep("clang-bridge-object")
    out = out.add_target(llvm_link_metadata)

    var stage1 = target_new(.Action, "stage1", "").output(bootstrap_compiler_bin("with-stage1"))
    stage1.action = run_with_compiler_build_action
    stage1 = stage1.compiler("seed")
    stage1 = stage1.input("out/gen/main.w")
    stage1 = target_with_compiler_source_inputs(move stage1, ctx)
    stage1 = stage1.arg("-O1")
    stage1 = stage1.extra_output("out/command/stage1")
    stage1 = stage1.extra_output("out/.build-state/seed-input.json")
    stage1 = stage1.timeout(1800000)
    stage1 = stage1.input(host_bin("out/bin/with-sha256"))
    // The ABI stamp every stage binary carries is sha256 of this record; a
    // re-record re-links (and re-stamps) the stage.
    stage1 = stage1.input("docs/with-abi.sha256")
    stage1 = stage1.write_scope("out/bootstrap/bin")
    stage1 = stage1.write_scope("out/.build-state")
    stage1 = stage1.dep("compiler-main-source")
    stage1 = stage1.dep("compat-runtime-source")
    stage1 = stage1.dep("embedded-clang-resource-source")
    stage1 = stage1.dep("compiler-no-c-export")
    stage1 = stage1.dep("prepare-bootstrap-link-root")
    stage1 = stage1.dep("with-sha256")
    out = out.add_target(stage1)

    // Dev tier (D14): the sanctioned iterate loop. One self-compile —
    // seed → stage1 — yields a testable compiler at out/bootstrap/bin/
    // with-stage1 in ~3.5 min. The full chain + fixpoint battery remains
    // mandatory at commit/reseed/release tier.
    var dev = target_new(.Group, "dev", "")
    dev = dev.dep("stage1")
    out = out.add_target(dev)

    var stage2 = target_new(.Action, "stage2", "").output(stage_compiler_bin("with-stage2"))
    stage2.action = run_with_compiler_build_action
    stage2 = stage2.compiler(bootstrap_compiler_bin("with-stage1"))
    stage2 = stage2.input("out/gen/main.w")
    stage2 = target_with_compiler_source_inputs(move stage2, ctx)
    stage2 = stage2.arg("-O1")
    stage2 = stage2.extra_output("out/command/stage2")
    stage2 = stage2.timeout(1800000)
    stage2 = stage2.input("docs/with-abi.sha256")
    stage2 = stage2.write_scope("out/stage/bin")
    stage2 = stage2.dep("stage1")
    stage2 = stage2.dep("compiler-main-source")
    stage2 = stage2.dep("compat-runtime-source")
    stage2 = stage2.dep("embedded-clang-resource-source")
    out = out.add_target(stage2)

    var stage3 = target_new(.Action, "stage3", "").output(stage_compiler_bin("with-stage3"))
    stage3.action = run_with_compiler_build_action
    stage3 = stage3.compiler(stage_compiler_bin("with-stage2"))
    stage3 = stage3.input("out/gen/main.w")
    stage3 = target_with_compiler_source_inputs(move stage3, ctx)
    stage3 = stage3.arg("-O1")
    stage3 = stage3.extra_output("out/command/stage3")
    stage3 = stage3.timeout(1800000)
    stage3 = stage3.input("docs/with-abi.sha256")
    stage3 = stage3.write_scope("out/stage/bin")
    stage3 = stage3.dep("stage2")
    stage3 = stage3.dep("compiler-main-source")
    stage3 = stage3.dep("compat-runtime-source")
    stage3 = stage3.dep("embedded-clang-resource-source")
    out = out.add_target(stage3)

    var stage2_fixpoint = target_new(.Action, "stage2-fixpoint-object", "").output(stage_compiler_obj("with-stage2-fixpoint.o"))
    stage2_fixpoint.action = run_with_compiler_build_action
    stage2_fixpoint = stage2_fixpoint.compiler(bootstrap_compiler_bin("with-stage1"))
    stage2_fixpoint = stage2_fixpoint.input("out/gen/main.w")
    stage2_fixpoint = target_with_compiler_source_inputs(move stage2_fixpoint, ctx)
    stage2_fixpoint = stage2_fixpoint.arg("--emit-obj")
    stage2_fixpoint = stage2_fixpoint.arg("-O1")
    stage2_fixpoint = stage2_fixpoint.extra_output("out/command/stage2-fixpoint-object")
    stage2_fixpoint = stage2_fixpoint.timeout(1800000)
    stage2_fixpoint = stage2_fixpoint.write_scope("out/stage/bin")
    stage2_fixpoint = stage2_fixpoint.dep("stage1")
    stage2_fixpoint = stage2_fixpoint.dep("compiler-main-source")
    stage2_fixpoint = stage2_fixpoint.dep("compat-runtime-source")
    stage2_fixpoint = stage2_fixpoint.dep("embedded-clang-resource-source")
    out = out.add_target(stage2_fixpoint)

    var stage3_fixpoint = target_new(.Action, "stage3-fixpoint-object", "").output(stage_compiler_obj("with-stage3-fixpoint.o"))
    stage3_fixpoint.action = run_with_compiler_build_action
    stage3_fixpoint = stage3_fixpoint.compiler(stage_compiler_bin("with-stage2"))
    stage3_fixpoint = stage3_fixpoint.input("out/gen/main.w")
    stage3_fixpoint = target_with_compiler_source_inputs(move stage3_fixpoint, ctx)
    stage3_fixpoint = stage3_fixpoint.arg("--emit-obj")
    stage3_fixpoint = stage3_fixpoint.arg("-O1")
    stage3_fixpoint = stage3_fixpoint.extra_output("out/command/stage3-fixpoint-object")
    stage3_fixpoint = stage3_fixpoint.timeout(1800000)
    stage3_fixpoint = stage3_fixpoint.write_scope("out/stage/bin")
    stage3_fixpoint = stage3_fixpoint.dep("stage2")
    stage3_fixpoint = stage3_fixpoint.dep("compiler-main-source")
    stage3_fixpoint = stage3_fixpoint.dep("compat-runtime-source")
    stage3_fixpoint = stage3_fixpoint.dep("embedded-clang-resource-source")
    out = out.add_target(stage3_fixpoint)

    var selfcheck = target_new(.RunCorpusTest, "selfcheck", stage_compiler_bin("with-stage2"))
    selfcheck = selfcheck.output("out/corpus/selfcheck")
    selfcheck = selfcheck.arg("check")
    selfcheck = selfcheck.arg("src/main.w")
    selfcheck = selfcheck.dep("stage2")
    out = out.add_target(selfcheck)

    var fixpoint_compare = target_new(.FixpointCompare, "fixpoint-compare", stage_compiler_obj("with-stage2-fixpoint.o"))
    fixpoint_compare = fixpoint_compare.arg(stage_compiler_obj("with-stage3-fixpoint.o"))
    fixpoint_compare = fixpoint_compare.dep("stage2-fixpoint-object")
    fixpoint_compare = fixpoint_compare.dep("stage3-fixpoint-object")
    out = out.add_target(fixpoint_compare)

    var bless_manifest = target_new(.Action, "bless-manifest", "").output("out/.build-state/blessed-manifest")
    bless_manifest.action = run_bless_manifest_action
    bless_manifest = bless_manifest.write_scope("out/.build-state")
    bless_manifest = bless_manifest.dep("fixpoint-compare")
    out = out.add_target(bless_manifest)

    // D19: the fixpoint tier records what it verified (object shas bound to
    // the release binary) so bless steps read evidence instead of re-deriving.
    var fixpoint_evidence = target_new(.Action, "fixpoint-evidence", "").output("out/.build-state/fixpoint-evidence.json")
    fixpoint_evidence.action = run_fixpoint_evidence_action
    fixpoint_evidence = fixpoint_evidence.input(host_bin("out/bin/with-sha256"))
    fixpoint_evidence = fixpoint_evidence.input(stage_compiler_obj("with-stage2-fixpoint.o"))
    fixpoint_evidence = fixpoint_evidence.input(stage_compiler_obj("with-stage3-fixpoint.o"))
    fixpoint_evidence = fixpoint_evidence.input(release_compiler_bin("with"))
    fixpoint_evidence = fixpoint_evidence.write_scope("out/.build-state")
    fixpoint_evidence = fixpoint_evidence.write_scope("out/command/fixpoint-evidence")
    fixpoint_evidence = fixpoint_evidence.dep("fixpoint-compare")
    fixpoint_evidence = fixpoint_evidence.dep("stage2-fixpoint-object")
    fixpoint_evidence = fixpoint_evidence.dep("stage3-fixpoint-object")
    fixpoint_evidence = fixpoint_evidence.dep("with-sha256")
    fixpoint_evidence = fixpoint_evidence.dep("build")
    out = out.add_target(fixpoint_evidence)

    var fixpoint = target_new(.Group, "fixpoint", "")
    fixpoint = fixpoint.dep("fixpoint-compare")
    fixpoint = fixpoint.dep("bless-manifest")
    fixpoint = fixpoint.dep("fixpoint-evidence")
    out = out.add_target(fixpoint)

    var fixpoint_diff = target_new(.Action, "fixpoint-diff", "").output("out/fixpoint-diff/report.txt")
    fixpoint_diff.action = run_fixpoint_diff_action
    fixpoint_diff = fixpoint_diff.dep("stage2")
    fixpoint_diff = fixpoint_diff.dep("stage2-fixpoint-object")
    fixpoint_diff = fixpoint_diff.dep("stage3-fixpoint-object")
    fixpoint_diff = fixpoint_diff.write_scope("out/fixpoint-diff")
    out = out.add_target(fixpoint_diff)

    var verified = target_new(.Group, "verified-existing-stage", "")
    verified = verified.dep("selfcheck")
    verified = verified.dep("fixpoint")
    out = out.add_target(verified)

    // D30 R1c (#761 closed out): out/lib rt objects are stage2-built again —
    // the ad053bea seed pin retired with the plain-consuming-str runtime
    // surface. Every remaining export is &str/pointer-honest, disarms its
    // by-value local (with_vec_push_str), never returns (with_panic), or is
    // an unreachable weak stub, so both compiler generations emit the same
    // ownership behavior for every reachable body.
    out = out.add_target(with_object_target("rt-core-object", stage_compiler_bin("with-stage2"), "rt/rt_core.w", "out/lib/rt_core.o", "-O1", "stage2"))
    out = out.add_target(with_object_target("rt-platform-object", stage_compiler_bin("with-stage2"), host_runtime.platform_source, host_runtime.platform_object, "-O1", "stage2"))
    let empty_syms = embedded_platform_symbols()
    for ei in 0..empty_syms.len() as i32:
        let esym = empty_syms.get(ei as i64)
        if esym != host_runtime.platform_symbol:
            out = out.add_target(empty_file_target(empty_platform_blob_target("empty-", esym), empty_platform_blob_path("out/lib", esym)))
    out = out.add_target(with_object_target("cimport-stubs-object", stage_compiler_bin("with-stage2"), "rt/cimport_stubs.w", "out/lib/cimport_stubs.o", "-O1", "stage2"))
    var compat_runtime_obj = with_object_target("compat-runtime-object", stage_compiler_bin("with-stage2"), "out/gen/compat_runtime.w", "out/lib/compat_runtime.o", "-O1", "stage2")
    compat_runtime_obj = compat_runtime_obj.dep("compat-runtime-source")
    out = out.add_target(compat_runtime_obj)
    out = out.add_target(with_object_target("panic-runtime-object", stage_compiler_bin("with-stage2"), "rt/panic_runtime.w", "out/lib/panic_runtime.o", "-O1", "stage2"))
    out = out.add_target(with_ir_target_overflow("regex-runtime-ir", stage_compiler_bin("with-stage2"), "rt/regex_runtime.w", "out/tmp/regex_runtime.ll", "stage2", "wrap"))

    var regex_runtime = target_new(.CompileLlvmIrObject, "regex-runtime-object", "out/tmp/regex_runtime.ll").output("out/lib/regex_runtime.o")
    regex_runtime = regex_runtime.dep("regex-runtime-ir")
    out = out.add_target(regex_runtime)

    out = out.add_target(with_object_target("fiber-stubs-object", stage_compiler_bin("with-stage2"), "rt/fiber_stubs.w", "out/lib/fiber_stubs.o", "-O1", "stage2"))
    out = out.add_target(with_object_target("channel-runtime-object", stage_compiler_bin("with-stage2"), "rt/channel_runtime.w", "out/lib/channel_runtime.o", "-O1", "stage2"))
    out = out.add_target(with_object_target("fiber-runtime-object", stage_compiler_bin("with-stage2"), "rt/fiber_runtime.w", "out/lib/fiber_runtime.o", "-O1", "stage2"))
    out = out.add_target(with_object_target("fiber-core-object", stage_compiler_bin("with-stage2"), host_runtime.fiber_core_source, "out/lib/fiber.o", "-O1", "stage2"))

    var fiber_asm = target_new(.CompileAsmObject, "fiber-asm-object", host_runtime.fiber_asm_source.clone()).output("out/lib/fiber_asm.o")
    out = out.add_target(fiber_asm)

    var embedded_objects = target_new(.EmbedObjectFiles, "embedded-objects-asm", "").output("out/lib/embedded_objects.s")
    embedded_objects = embedded_objects.input("out/lib/cimport_stubs.o")
    embedded_objects = embedded_objects.arg("cimport_stubs_o")
    embedded_objects = embedded_objects.input("out/lib/compat_runtime.o")
    embedded_objects = embedded_objects.arg("compat_runtime_o")
    embedded_objects = embedded_objects.input("out/lib/panic_runtime.o")
    embedded_objects = embedded_objects.arg("panic_runtime_o")
    embedded_objects = embedded_objects.input("out/lib/regex_runtime.o")
    embedded_objects = embedded_objects.arg("regex_runtime_o")
    embedded_objects = embedded_objects.input("out/lib/fiber_stubs.o")
    embedded_objects = embedded_objects.arg("fiber_stubs_o")
    embedded_objects = embedded_objects.input("out/lib/channel_runtime.o")
    embedded_objects = embedded_objects.arg("channel_runtime_o")
    embedded_objects = embedded_objects.input("out/lib/fiber_runtime.o")
    embedded_objects = embedded_objects.arg("fiber_runtime_o")
    embedded_objects = embedded_objects.input("out/lib/fiber.o")
    embedded_objects = embedded_objects.arg("fiber_o")
    embedded_objects = embedded_objects.input("out/lib/fiber_asm.o")
    embedded_objects = embedded_objects.arg("fiber_asm_o")
    embedded_objects = embedded_objects.input("out/lib/rt_core.o")
    embedded_objects = embedded_objects.arg("rt_core_o")
    embedded_objects = embedded_objects.input(build_owned_text(host_runtime.platform_object))
    embedded_objects = embedded_objects.arg(host_runtime.platform_symbol)
    for ei2 in 0..empty_syms.len() as i32:
        let esym2 = empty_syms.get(ei2 as i64)
        if esym2 != host_runtime.platform_symbol:
            embedded_objects = embedded_objects.input(empty_platform_blob_path("out/lib", esym2))
            embedded_objects = embedded_objects.arg(build_owned_text(esym2))
    // Every consumed object's producer, declared (#680 edge audit).
    embedded_objects = embedded_objects.dep("cimport-stubs-object")
    embedded_objects = embedded_objects.dep("compat-runtime-object")
    embedded_objects = embedded_objects.dep("panic-runtime-object")
    embedded_objects = embedded_objects.dep("regex-runtime-object")
    embedded_objects = embedded_objects.dep("fiber-stubs-object")
    embedded_objects = embedded_objects.dep("channel-runtime-object")
    embedded_objects = embedded_objects.dep("fiber-runtime-object")
    embedded_objects = embedded_objects.dep("fiber-core-object")
    embedded_objects = embedded_objects.dep("fiber-asm-object")
    embedded_objects = embedded_objects.dep("rt-core-object")
    embedded_objects = embedded_objects.dep("rt-platform-object")
    for ei3 in 0..empty_syms.len() as i32:
        let esym3 = empty_syms.get(ei3 as i64)
        if esym3 != host_runtime.platform_symbol:
            embedded_objects = embedded_objects.dep(empty_platform_blob_target("empty-", esym3))
    out = out.add_target(embedded_objects)

    var embedded_objects_obj = target_new(.CompileAsmObject, "embedded-objects-object", "out/lib/embedded_objects.s").output("out/lib/embedded_objects.o")
    embedded_objects_obj = embedded_objects_obj.dep("embedded-objects-asm")
    out = out.add_target(embedded_objects_obj)

    var runtime = target_new(.Group, "runtime", "")
    runtime = runtime.dep("embedded-objects-object")
    for ei4 in 0..empty_syms.len() as i32:
        let esym4 = empty_syms.get(ei4 as i64)
        if esym4 != host_runtime.platform_symbol:
            runtime = runtime.dep(empty_platform_blob_target("empty-", esym4))
    out = out.add_target(runtime)

    // ── Cross-target runtime (linux) ────────────────────────────────
    // `with build :cross-rt` (linux_x86_64) / `:cross-rt-arm`
    // (linux_aarch64) build the full cross runtime + compiler link
    // inputs into out/lib/cross/<tag>/ using the freshly built native
    // compiler's --target support. The link stage resolves cross links
    // exclusively from that directory (§18.5). Note: these graph
    // actions must be driven by a --target-capable compiler
    // (WITH=out/release/bin/with) until the seed is updated.
    out = add_cross_rt_targets(move out, "linux_x86_64", "cross-", "cross-rt")
    out = add_cross_rt_targets(move out, "linux_aarch64", "cross-arm-", "cross-rt-arm")

    // ── Cross-target runtime (windows_x86_64) ───────────────────────
    // `with build :cross-rt-windows` builds the full windows_x86_64
    // runtime + compiler link inputs into out/lib/cross/windows_x86_64/
    // (COFF objects, windows triple) so a `--target x86_64-pc-windows-msvc`
    // link resolves entirely from that directory (§18.5). Mirrors the
    // linux cross-rt set; fiber core/asm are the windows variants.
    out = out.add_target(cross_windows_object_target("cross-win-rt-core-object", "rt/rt_core.w", "-O2"))
    out = out.add_target(cross_windows_object_target_named("cross-win-rt-platform-object", "rt/windows_x86_64.w", "rt_windows_x86_64.o", "-O2"))
    out = out.add_target(cross_windows_object_target("cross-win-cimport-stubs-object", "rt/cimport_stubs.w", "-O1"))
    var cross_win_compat = cross_windows_object_target_named("cross-win-compat-runtime-object", "out/gen/compat_runtime.w", "compat_runtime.o", "-O1")
    cross_win_compat = cross_win_compat.dep("compat-runtime-source")
    out = out.add_target(cross_win_compat)
    out = out.add_target(cross_windows_object_target("cross-win-panic-runtime-object", "rt/panic_runtime.w", "-O1"))
    out = out.add_target(cross_windows_object_target("cross-win-fiber-stubs-object", "rt/fiber_stubs.w", "-O1"))
    out = out.add_target(cross_windows_object_target("cross-win-channel-runtime-object", "rt/channel_runtime.w", "-O1"))
    out = out.add_target(cross_windows_object_target("cross-win-fiber-runtime-object", "rt/fiber_runtime.w", "-O1"))
    out = out.add_target(cross_windows_object_target_named("cross-win-fiber-core-object", "rt/fiber_core_windows.w", "fiber.o", "-O1"))
    out = out.add_target(cross_windows_object_target_named("cross-win-llvm-bridge-object", "src/compiler/LlvmBridge.w", "llvm_bridge.o", "-O1"))
    out = out.add_target(cross_windows_object_target_named("cross-win-clang-bridge-object", "src/compiler/ClangBridge.w", "clang_bridge.o", "-O1"))

    var cross_win_regex_ir = with_ir_target_overflow("cross-win-regex-runtime-ir", release_compiler_bin("with"), "rt/regex_runtime.w", "out/tmp/cross_win_regex_runtime.ll", "build", "wrap")
    cross_win_regex_ir = cross_win_regex_ir.arg("--target=" ++ cross_windows_triple())
    out = out.add_target(cross_win_regex_ir)
    var cross_win_regex = target_new(.CompileLlvmIrObject, "cross-win-regex-runtime-object", "out/tmp/cross_win_regex_runtime.ll").output(cross_windows_dir() ++ "/regex_runtime.o")
    cross_win_regex = cross_win_regex.dep("cross-win-regex-runtime-ir")
    out = out.add_target(cross_win_regex)

    var cross_win_fiber_asm = target_new(.CompileAsmObject, "cross-win-fiber-asm-object", "runtime/fiber_asm_windows_x86_64.s").output(cross_windows_dir() ++ "/fiber_asm.o")
    cross_win_fiber_asm = cross_win_fiber_asm.arg("triple=" ++ cross_windows_triple())
    out = out.add_target(cross_win_fiber_asm)

    var cross_win_embedded = target_new(.EmbedObjectFiles, "cross-win-embedded-objects-asm", "windows_x86_64").output(cross_windows_dir() ++ "/embedded_objects.s")
    cross_win_embedded = cross_win_embedded.input(cross_windows_dir() ++ "/cimport_stubs.o")
    cross_win_embedded = cross_win_embedded.arg("cimport_stubs_o")
    cross_win_embedded = cross_win_embedded.input(cross_windows_dir() ++ "/compat_runtime.o")
    cross_win_embedded = cross_win_embedded.arg("compat_runtime_o")
    cross_win_embedded = cross_win_embedded.input(cross_windows_dir() ++ "/panic_runtime.o")
    cross_win_embedded = cross_win_embedded.arg("panic_runtime_o")
    cross_win_embedded = cross_win_embedded.input(cross_windows_dir() ++ "/regex_runtime.o")
    cross_win_embedded = cross_win_embedded.arg("regex_runtime_o")
    cross_win_embedded = cross_win_embedded.input(cross_windows_dir() ++ "/fiber_stubs.o")
    cross_win_embedded = cross_win_embedded.arg("fiber_stubs_o")
    cross_win_embedded = cross_win_embedded.input(cross_windows_dir() ++ "/channel_runtime.o")
    cross_win_embedded = cross_win_embedded.arg("channel_runtime_o")
    cross_win_embedded = cross_win_embedded.input(cross_windows_dir() ++ "/fiber_runtime.o")
    cross_win_embedded = cross_win_embedded.arg("fiber_runtime_o")
    cross_win_embedded = cross_win_embedded.input(cross_windows_dir() ++ "/fiber.o")
    cross_win_embedded = cross_win_embedded.arg("fiber_o")
    cross_win_embedded = cross_win_embedded.input(cross_windows_dir() ++ "/fiber_asm.o")
    cross_win_embedded = cross_win_embedded.arg("fiber_asm_o")
    cross_win_embedded = cross_win_embedded.input(cross_windows_dir() ++ "/rt_core.o")
    cross_win_embedded = cross_win_embedded.arg("rt_core_o")
    cross_win_embedded = cross_win_embedded.input(cross_windows_dir() ++ "/rt_windows_x86_64.o")
    cross_win_embedded = cross_win_embedded.arg("rt_windows_x86_64_o")
    cross_win_embedded = cross_win_embedded.dep("cross-win-cimport-stubs-object")
    cross_win_embedded = cross_win_embedded.dep("cross-win-compat-runtime-object")
    cross_win_embedded = cross_win_embedded.dep("cross-win-panic-runtime-object")
    cross_win_embedded = cross_win_embedded.dep("cross-win-regex-runtime-object")
    cross_win_embedded = cross_win_embedded.dep("cross-win-fiber-stubs-object")
    cross_win_embedded = cross_win_embedded.dep("cross-win-channel-runtime-object")
    cross_win_embedded = cross_win_embedded.dep("cross-win-fiber-runtime-object")
    cross_win_embedded = cross_win_embedded.dep("cross-win-fiber-core-object")
    cross_win_embedded = cross_win_embedded.dep("cross-win-fiber-asm-object")
    cross_win_embedded = cross_win_embedded.dep("cross-win-rt-core-object")
    cross_win_embedded = cross_win_embedded.dep("cross-win-rt-platform-object")
    out = out.add_target(cross_win_embedded)

    var cross_win_embedded_obj = target_new(.CompileAsmObject, "cross-win-embedded-objects-object", cross_windows_dir() ++ "/embedded_objects.s").output(cross_windows_dir() ++ "/embedded_objects.o")
    cross_win_embedded_obj = cross_win_embedded_obj.arg("triple=" ++ cross_windows_triple())
    cross_win_embedded_obj = cross_win_embedded_obj.dep("cross-win-embedded-objects-asm")
    out = out.add_target(cross_win_embedded_obj)

    var cross_win_ld_rsp = target_new(.Action, "cross-win-llvm-link-metadata", "").output(cross_windows_dir() ++ "/llvm_ld.rsp")
    cross_win_ld_rsp.action = run_cross_windows_llvm_link_metadata_action
    cross_win_ld_rsp = cross_win_ld_rsp.write_scope(cross_windows_dir())
    cross_win_ld_rsp = cross_win_ld_rsp.write_scope("out/command/cross-win-llvm-link-metadata")
    out = out.add_target(cross_win_ld_rsp)

    var cross_rt_windows = target_new(.Group, "cross-rt-windows", "")
    cross_rt_windows = cross_rt_windows.dep("cross-win-embedded-objects-object")
    cross_rt_windows = cross_rt_windows.dep("cross-win-llvm-bridge-object")
    cross_rt_windows = cross_rt_windows.dep("cross-win-clang-bridge-object")
    cross_rt_windows = cross_rt_windows.dep("cross-win-llvm-link-metadata")
    out = out.add_target(cross_rt_windows)

    // ── Cross-target runtime (windows_aarch64) ──────────────────────
    // `with build :cross-rt-windows-aarch64` builds the full windows_aarch64
    // runtime + compiler link inputs into out/lib/cross/windows_aarch64/
    // (COFF/ARM64 objects, aarch64-pc-windows-msvc triple) so a
    // `--target aarch64-pc-windows-msvc` link resolves entirely from that
    // directory (§18.5). Mirrors the windows_x86_64 cross-rt set; fiber
    // core is the windows variant, fiber asm the arm64 windows variant.
    out = out.add_target(cross_windows_aarch64_object_target("cross-winarm-rt-core-object", "rt/rt_core.w", "-O2"))
    out = out.add_target(cross_windows_aarch64_object_target_named("cross-winarm-rt-platform-object", "rt/windows_aarch64.w", "rt_windows_aarch64.o", "-O2"))
    out = out.add_target(cross_windows_aarch64_object_target("cross-winarm-cimport-stubs-object", "rt/cimport_stubs.w", "-O1"))
    var cross_winarm_compat = cross_windows_aarch64_object_target_named("cross-winarm-compat-runtime-object", "out/gen/compat_runtime.w", "compat_runtime.o", "-O1")
    cross_winarm_compat = cross_winarm_compat.dep("compat-runtime-source")
    out = out.add_target(cross_winarm_compat)
    out = out.add_target(cross_windows_aarch64_object_target("cross-winarm-panic-runtime-object", "rt/panic_runtime.w", "-O1"))
    out = out.add_target(cross_windows_aarch64_object_target("cross-winarm-fiber-stubs-object", "rt/fiber_stubs.w", "-O1"))
    out = out.add_target(cross_windows_aarch64_object_target("cross-winarm-channel-runtime-object", "rt/channel_runtime.w", "-O1"))
    out = out.add_target(cross_windows_aarch64_object_target("cross-winarm-fiber-runtime-object", "rt/fiber_runtime.w", "-O1"))
    out = out.add_target(cross_windows_aarch64_object_target_named("cross-winarm-fiber-core-object", "rt/fiber_core_windows.w", "fiber.o", "-O1"))
    out = out.add_target(cross_windows_aarch64_object_target_named("cross-winarm-llvm-bridge-object", "src/compiler/LlvmBridge.w", "llvm_bridge.o", "-O1"))
    out = out.add_target(cross_windows_aarch64_object_target_named("cross-winarm-clang-bridge-object", "src/compiler/ClangBridge.w", "clang_bridge.o", "-O1"))

    var cross_winarm_regex_ir = with_ir_target_overflow("cross-winarm-regex-runtime-ir", release_compiler_bin("with"), "rt/regex_runtime.w", "out/tmp/cross_winarm_regex_runtime.ll", "build", "wrap")
    cross_winarm_regex_ir = cross_winarm_regex_ir.arg("--target=" ++ cross_windows_aarch64_triple())
    out = out.add_target(cross_winarm_regex_ir)
    var cross_winarm_regex = target_new(.CompileLlvmIrObject, "cross-winarm-regex-runtime-object", "out/tmp/cross_winarm_regex_runtime.ll").output(cross_windows_aarch64_dir() ++ "/regex_runtime.o")
    cross_winarm_regex = cross_winarm_regex.dep("cross-winarm-regex-runtime-ir")
    out = out.add_target(cross_winarm_regex)

    var cross_winarm_fiber_asm = target_new(.CompileAsmObject, "cross-winarm-fiber-asm-object", "runtime/fiber_asm_windows_aarch64.s").output(cross_windows_aarch64_dir() ++ "/fiber_asm.o")
    cross_winarm_fiber_asm = cross_winarm_fiber_asm.arg("triple=" ++ cross_windows_aarch64_triple())
    out = out.add_target(cross_winarm_fiber_asm)

    var cross_winarm_embedded = target_new(.EmbedObjectFiles, "cross-winarm-embedded-objects-asm", "windows_aarch64").output(cross_windows_aarch64_dir() ++ "/embedded_objects.s")
    cross_winarm_embedded = cross_winarm_embedded.input(cross_windows_aarch64_dir() ++ "/cimport_stubs.o")
    cross_winarm_embedded = cross_winarm_embedded.arg("cimport_stubs_o")
    cross_winarm_embedded = cross_winarm_embedded.input(cross_windows_aarch64_dir() ++ "/compat_runtime.o")
    cross_winarm_embedded = cross_winarm_embedded.arg("compat_runtime_o")
    cross_winarm_embedded = cross_winarm_embedded.input(cross_windows_aarch64_dir() ++ "/panic_runtime.o")
    cross_winarm_embedded = cross_winarm_embedded.arg("panic_runtime_o")
    cross_winarm_embedded = cross_winarm_embedded.input(cross_windows_aarch64_dir() ++ "/regex_runtime.o")
    cross_winarm_embedded = cross_winarm_embedded.arg("regex_runtime_o")
    cross_winarm_embedded = cross_winarm_embedded.input(cross_windows_aarch64_dir() ++ "/fiber_stubs.o")
    cross_winarm_embedded = cross_winarm_embedded.arg("fiber_stubs_o")
    cross_winarm_embedded = cross_winarm_embedded.input(cross_windows_aarch64_dir() ++ "/channel_runtime.o")
    cross_winarm_embedded = cross_winarm_embedded.arg("channel_runtime_o")
    cross_winarm_embedded = cross_winarm_embedded.input(cross_windows_aarch64_dir() ++ "/fiber_runtime.o")
    cross_winarm_embedded = cross_winarm_embedded.arg("fiber_runtime_o")
    cross_winarm_embedded = cross_winarm_embedded.input(cross_windows_aarch64_dir() ++ "/fiber.o")
    cross_winarm_embedded = cross_winarm_embedded.arg("fiber_o")
    cross_winarm_embedded = cross_winarm_embedded.input(cross_windows_aarch64_dir() ++ "/fiber_asm.o")
    cross_winarm_embedded = cross_winarm_embedded.arg("fiber_asm_o")
    cross_winarm_embedded = cross_winarm_embedded.input(cross_windows_aarch64_dir() ++ "/rt_core.o")
    cross_winarm_embedded = cross_winarm_embedded.arg("rt_core_o")
    cross_winarm_embedded = cross_winarm_embedded.input(cross_windows_aarch64_dir() ++ "/rt_windows_aarch64.o")
    cross_winarm_embedded = cross_winarm_embedded.arg("rt_windows_aarch64_o")
    cross_winarm_embedded = cross_winarm_embedded.dep("cross-winarm-cimport-stubs-object")
    cross_winarm_embedded = cross_winarm_embedded.dep("cross-winarm-compat-runtime-object")
    cross_winarm_embedded = cross_winarm_embedded.dep("cross-winarm-panic-runtime-object")
    cross_winarm_embedded = cross_winarm_embedded.dep("cross-winarm-regex-runtime-object")
    cross_winarm_embedded = cross_winarm_embedded.dep("cross-winarm-fiber-stubs-object")
    cross_winarm_embedded = cross_winarm_embedded.dep("cross-winarm-channel-runtime-object")
    cross_winarm_embedded = cross_winarm_embedded.dep("cross-winarm-fiber-runtime-object")
    cross_winarm_embedded = cross_winarm_embedded.dep("cross-winarm-fiber-core-object")
    cross_winarm_embedded = cross_winarm_embedded.dep("cross-winarm-fiber-asm-object")
    cross_winarm_embedded = cross_winarm_embedded.dep("cross-winarm-rt-core-object")
    cross_winarm_embedded = cross_winarm_embedded.dep("cross-winarm-rt-platform-object")
    out = out.add_target(cross_winarm_embedded)

    var cross_winarm_embedded_obj = target_new(.CompileAsmObject, "cross-winarm-embedded-objects-object", cross_windows_aarch64_dir() ++ "/embedded_objects.s").output(cross_windows_aarch64_dir() ++ "/embedded_objects.o")
    cross_winarm_embedded_obj = cross_winarm_embedded_obj.arg("triple=" ++ cross_windows_aarch64_triple())
    cross_winarm_embedded_obj = cross_winarm_embedded_obj.dep("cross-winarm-embedded-objects-asm")
    out = out.add_target(cross_winarm_embedded_obj)

    var cross_winarm_ld_rsp = target_new(.Action, "cross-winarm-llvm-link-metadata", "").output(cross_windows_aarch64_dir() ++ "/llvm_ld.rsp")
    cross_winarm_ld_rsp.action = run_cross_windows_aarch64_llvm_link_metadata_action
    cross_winarm_ld_rsp = cross_winarm_ld_rsp.write_scope(cross_windows_aarch64_dir())
    cross_winarm_ld_rsp = cross_winarm_ld_rsp.write_scope("out/command/cross-winarm-llvm-link-metadata")
    out = out.add_target(cross_winarm_ld_rsp)

    var cross_rt_windows_aarch64 = target_new(.Group, "cross-rt-windows-aarch64", "")
    cross_rt_windows_aarch64 = cross_rt_windows_aarch64.dep("cross-winarm-embedded-objects-object")
    cross_rt_windows_aarch64 = cross_rt_windows_aarch64.dep("cross-winarm-llvm-bridge-object")
    cross_rt_windows_aarch64 = cross_rt_windows_aarch64.dep("cross-winarm-clang-bridge-object")
    cross_rt_windows_aarch64 = cross_rt_windows_aarch64.dep("cross-winarm-llvm-link-metadata")
    out = out.add_target(cross_rt_windows_aarch64)

    // The compiler links to an UNSTAMPED intermediate whose inputs (out/gen/main.w
    // + src) are commit-independent, so it caches across commits (#650). A cheap
    // downstream `build` Action patches the version into the final binary. When
    // commit identity is the only change, this expensive compile stays cached.
    var compiler = target_new(.Action, "link-compiler", "").output(release_compiler_bin("with") ++ ".unstamped")
    compiler.action = run_with_compiler_build_action
    compiler = compiler.compiler(stage_compiler_bin("with-stage2"))
    compiler = compiler.input("out/gen/main.w")
    compiler = target_with_compiler_source_inputs(move compiler, ctx)
    compiler = compiler.arg("-O1")
    compiler = compiler.extra_output("out/command/link-compiler")
    compiler = compiler.timeout(1800000)
    compiler = compiler.write_scope("out/release/bin")
    compiler = compiler.dep("compiler-main-source")
    compiler = compiler.dep("llvm-link-metadata")
    compiler = compiler.dep("embedded-objects-object")
    out = out.add_target(compiler)

    // Post-link version stamp: keeps the name `build` and the output path so every
    // .dep("build") edge and release_compiler_bin("with") consumer is unchanged.
    // Tracks .git/HEAD (via target_with_version_inputs) so it re-runs only when the
    // commit changes — a millisecond patch, never a recompile.
    var stamp = target_new(.Action, "build", "").output(release_compiler_bin("with"))
    stamp.action = run_patch_version_action
    stamp = stamp.input(release_compiler_bin("with") ++ ".unstamped")
    // The ABI stamp is sha256 of this record; a re-record must re-stamp.
    stamp = stamp.input("docs/with-abi.sha256")
    stamp = target_with_version_inputs(move stamp, ctx)
    stamp = stamp.extra_output("out/command/build")
    stamp = stamp.write_scope("out/release/bin")
    stamp = stamp.dep("link-compiler")
    out = out.add_target(stamp)

    var build_handoff = target_new(.CopyFile, "update-bin", release_compiler_bin("with")).output(host_bin("out/bin/with"))
    build_handoff = build_handoff.arg("0755")
    build_handoff = build_handoff.write_scope("out/bin")
    build_handoff = build_handoff.dep("build")
    out = out.add_target(build_handoff)

    var stack_budget_check = target_new(.Action, "stack-budget-check", "").output("out/test-graph/stack-budget-check")
    stack_budget_check.action = run_stack_budget_check_action
    stack_budget_check = stack_budget_check.input(release_compiler_bin("with"))
    stack_budget_check = stack_budget_check.dep("build")
    out = out.add_target(stack_budget_check)

    var emit_c_test = target_new(.Action, "emit-c-test", "").output("out/gen/.emit-c-test-stamp")
    emit_c_test.action = run_emit_c_test_action
    emit_c_test = emit_c_test.input(release_compiler_bin("with"))
    emit_c_test = emit_c_test.input("out/gen/versioned_main.w")
    emit_c_test = emit_c_test.extra_output("out/emit-c-test")
    emit_c_test = emit_c_test.extra_output("out/gen/wl_decls.h")
    emit_c_test = emit_c_test.extra_output("out/gen/wl_stubs.c")
    emit_c_test = emit_c_test.extra_output("out/command/emit-c-test")
    emit_c_test = emit_c_test.dep("build")
    emit_c_test = emit_c_test.dep("compiler-version-sources")
    out = out.add_target(emit_c_test)

    var emit_c_fixpoint = target_new(.Action, "emit-c-fixpoint", "").output("out/gen/.emit-c-fixpoint-stamp")
    emit_c_fixpoint.action = run_emit_c_fixpoint_action
    emit_c_fixpoint = emit_c_fixpoint.input("out/emit-c-test/main.c")
    emit_c_fixpoint = emit_c_fixpoint.input(host_bin("out/emit-c-test/with-from-c"))
    emit_c_fixpoint = emit_c_fixpoint.input("out/gen/versioned_main.w")
    emit_c_fixpoint = emit_c_fixpoint.extra_output("out/emit-c-test/main2.c")
    emit_c_fixpoint = emit_c_fixpoint.extra_output("out/command/emit-c-fixpoint")
    emit_c_fixpoint = emit_c_fixpoint.dep("emit-c-test")
    emit_c_fixpoint = emit_c_fixpoint.dep("compiler-version-sources")
    out = out.add_target(emit_c_fixpoint)

    var emit_c_roundtrip = target_new(.Action, "emit-c-roundtrip", "").output("out/gen/.emit-c-roundtrip-stamp")
    emit_c_roundtrip.action = run_emit_c_roundtrip_action
    emit_c_roundtrip = emit_c_roundtrip.input(release_compiler_bin("with"))
    emit_c_roundtrip = emit_c_roundtrip.input("out/gen/versioned_main.w")
    emit_c_roundtrip = emit_c_roundtrip.input("out/gen/version.txt")
    emit_c_roundtrip = emit_c_roundtrip.extra_output("out/emit-c-roundtrip")
    emit_c_roundtrip = emit_c_roundtrip.extra_output("out/gen/wl_decls.h")
    emit_c_roundtrip = emit_c_roundtrip.extra_output("out/gen/wl_stubs.c")
    emit_c_roundtrip = emit_c_roundtrip.extra_output("out/command/emit-c-roundtrip")
    emit_c_roundtrip = emit_c_roundtrip.dep("build")
    emit_c_roundtrip = emit_c_roundtrip.dep("compiler-version-sources")
    out = out.add_target(emit_c_roundtrip)

    var behavior_tests = target_new(.Test, "behavior-tests", "test/behavior/*.w")
    behavior_tests = behavior_tests.arg("compiler=" ++ release_compiler_bin("with"))
    behavior_tests = behavior_tests.allow_parallel()
    behavior_tests = behavior_tests.dep("build")
    out = out.add_target(behavior_tests)

    // Debug-allocator fixture lane (custom //! expect-debug-alloc directive; run
    // via tools/debug_drop.w, not the built-in test runner). See docs/debug-allocator.md.
    var debug_alloc_tests = target_new(.Action, "debug-alloc-tests", "").output("out/debug-alloc-tests")
    debug_alloc_tests = debug_alloc_tests.allow_parallel()
    debug_alloc_tests.action = run_debug_alloc_tests_action
    debug_alloc_tests = debug_alloc_tests.input(release_compiler_bin("with"))
    debug_alloc_tests = debug_alloc_tests.input("tools/debug_drop.w")
    debug_alloc_tests = debug_alloc_tests.input("test/debug_alloc")
    var drop_audit = target_new(.Action, "drop-audit", "").output("out/drop-audit")
    drop_audit.action = run_drop_audit_action
    drop_audit = drop_audit.input(release_compiler_bin("with"))
    drop_audit = drop_audit.input("tools/drop_audit.w")
    drop_audit = drop_audit.input("src/main")
    drop_audit = drop_audit.dep("build")
    drop_audit = drop_audit.write_scope("out/drop-audit")
    out = out.add_target(drop_audit)
    var move_audit = target_new(.Action, "move-audit", "").output("out/move-audit")
    move_audit = move_audit.allow_parallel()
    move_audit.action = run_move_audit_action
    move_audit = move_audit.input(release_compiler_bin("with"))
    move_audit = move_audit.input("tools/move_audit.w")
    move_audit = move_audit.input("src/main")
    move_audit = move_audit.dep("build")
    move_audit = move_audit.write_scope("out/move-audit")
    out = out.add_target(move_audit)
    debug_alloc_tests = debug_alloc_tests.dep("build")
    debug_alloc_tests = debug_alloc_tests.write_scope("out/debug-alloc-tests")
    out = out.add_target(debug_alloc_tests)

    var deep_debug_tool_tests = target_new(.Action, "deep-debug-tool-tests", "").output("out/deep-debug-tool-tests")
    deep_debug_tool_tests = deep_debug_tool_tests.allow_parallel()
    deep_debug_tool_tests.action = run_deep_debug_tool_tests_action
    deep_debug_tool_tests = deep_debug_tool_tests.input(release_compiler_bin("with"))
    deep_debug_tool_tests = deep_debug_tool_tests.dep("build")
    deep_debug_tool_tests = deep_debug_tool_tests.write_scope("out/deep-debug-tool-tests")
    out = out.add_target(deep_debug_tool_tests)

    // D38: the ABI-defining sources' recorded hash must match — an ABI change
    // without a WITH_ABI_VERSION bump fails the battery (docs/with-abi.md §7).
    var abi_hash_check = target_new(.Action, "abi-hash-check", "").output("out/abi-hash-check/stamp")
    abi_hash_check = abi_hash_check.allow_parallel()
    abi_hash_check.action = run_abi_hash_check_action
    abi_hash_check = abi_hash_check.input("src/FnAbi.w")
    abi_hash_check = abi_hash_check.input("src/TypeLayout.w")
    abi_hash_check = abi_hash_check.input("docs/with-abi.sha256")
    abi_hash_check = abi_hash_check.write_scope("out/abi-hash-check")
    out = out.add_target(abi_hash_check)

    var native_compile_error_tests = target_new(.Test, "native-compile-error-tests", "test/compile_errors/*.w")
    native_compile_error_tests = native_compile_error_tests.allow_parallel()
    native_compile_error_tests = native_compile_error_tests.arg("compiler=" ++ release_compiler_bin("with"))
    native_compile_error_tests = native_compile_error_tests.dep("build")
    native_compile_error_tests = native_compile_error_tests.dep("selfcheck")
    out = out.add_target(native_compile_error_tests)

    var native_codegen_tests = target_new(.Test, "native-codegen-tests", "test/codegen/*.w")
    native_codegen_tests = native_codegen_tests.allow_parallel()
    native_codegen_tests = native_codegen_tests.arg("compiler=" ++ release_compiler_bin("with"))
    native_codegen_tests = native_codegen_tests.dep("build")
    native_codegen_tests = native_codegen_tests.dep("selfcheck")
    out = out.add_target(native_codegen_tests)

    var native_spec_tests = target_new(.Test, "native-spec-tests", "test/spec/*.w")
    native_spec_tests = native_spec_tests.allow_parallel()
    native_spec_tests = native_spec_tests.arg("compiler=" ++ release_compiler_bin("with"))
    native_spec_tests = native_spec_tests.dep("build")
    native_spec_tests = native_spec_tests.dep("selfcheck")
    out = out.add_target(native_spec_tests)

    var comptime_diff_tests = target_new(.Test, "comptime-diff-tests", "test/comptime_diff/*.w")
    comptime_diff_tests = comptime_diff_tests.allow_parallel()
    comptime_diff_tests = comptime_diff_tests.arg("compiler=" ++ release_compiler_bin("with"))
    comptime_diff_tests = comptime_diff_tests.dep("build")
    comptime_diff_tests = comptime_diff_tests.dep("selfcheck")
    out = out.add_target(comptime_diff_tests)

    var native_phase_tests = target_new(.Test, "native-phase-tests", "test/phase/*.w")
    native_phase_tests = native_phase_tests.allow_parallel()
    native_phase_tests = native_phase_tests.arg("compiler=" ++ release_compiler_bin("with"))
    native_phase_tests = native_phase_tests.dep("build")
    native_phase_tests = native_phase_tests.dep("selfcheck")
    out = out.add_target(native_phase_tests)

    var internals_tests = target_new(.Test, "internals-tests", "test/internals/*.w")
    internals_tests = internals_tests.allow_parallel()
    internals_tests = internals_tests.arg("compiler=" ++ release_compiler_bin("with"))
    internals_tests = internals_tests.dep("build")
    internals_tests = internals_tests.dep("selfcheck")
    out = out.add_target(internals_tests)

    var lexer_tests = target_new(.Test, "lexer-tests", "test/lexer/*.w")
    lexer_tests = lexer_tests.allow_parallel()
    lexer_tests = lexer_tests.arg("compiler=" ++ release_compiler_bin("with"))
    lexer_tests = lexer_tests.dep("build")
    lexer_tests = lexer_tests.dep("selfcheck")
    out = out.add_target(lexer_tests)

    var parser_tests = target_new(.Test, "parser-tests", "test/parser/*.w")
    parser_tests = parser_tests.allow_parallel()
    parser_tests = parser_tests.arg("compiler=" ++ release_compiler_bin("with"))
    parser_tests = parser_tests.dep("build")
    parser_tests = parser_tests.dep("selfcheck")
    out = out.add_target(parser_tests)

    var cli_selfhost_smoke_tests = target_new(.Action, "cli-selfhost-smoke-tests", "").output("out/test-graph/cli-selfhost-smoke-tests")
    cli_selfhost_smoke_tests = cli_selfhost_smoke_tests.allow_parallel()
    cli_selfhost_smoke_tests.action = run_cli_selfhost_smoke_action
    cli_selfhost_smoke_tests = cli_selfhost_smoke_tests.input(release_compiler_bin("with"))
    cli_selfhost_smoke_tests = cli_selfhost_smoke_tests.dep("build")
    out = out.add_target(cli_selfhost_smoke_tests)

    var cli_selfhost_one_liner_tests = target_new(.Action, "cli-selfhost-one-liner-tests", "").output("out/test-graph/cli-selfhost-one-liner-tests")
    cli_selfhost_one_liner_tests = cli_selfhost_one_liner_tests.allow_parallel()
    cli_selfhost_one_liner_tests.action = run_cli_selfhost_one_liner_action
    cli_selfhost_one_liner_tests = cli_selfhost_one_liner_tests.input(release_compiler_bin("with"))
    cli_selfhost_one_liner_tests = cli_selfhost_one_liner_tests.dep("build")
    out = out.add_target(cli_selfhost_one_liner_tests)

    var cli_selfhost_fmt_tests = target_new(.Action, "cli-selfhost-fmt-tests", "").output("out/test-graph/cli-selfhost-fmt-tests")
    cli_selfhost_fmt_tests = cli_selfhost_fmt_tests.allow_parallel()
    cli_selfhost_fmt_tests.action = run_cli_selfhost_fmt_action
    cli_selfhost_fmt_tests = cli_selfhost_fmt_tests.input(release_compiler_bin("with"))
    cli_selfhost_fmt_tests = cli_selfhost_fmt_tests.dep("build")
    out = out.add_target(cli_selfhost_fmt_tests)

    var cli_selfhost_object_symbol_tests = target_new(.Action, "cli-selfhost-object-symbol-tests", "").output("out/test-graph/cli-selfhost-object-symbol-tests")
    cli_selfhost_object_symbol_tests = cli_selfhost_object_symbol_tests.allow_parallel()
    cli_selfhost_object_symbol_tests.action = run_cli_selfhost_object_symbol_action
    cli_selfhost_object_symbol_tests = cli_selfhost_object_symbol_tests.arg("nm")
    cli_selfhost_object_symbol_tests = cli_selfhost_object_symbol_tests.input(release_compiler_bin("with"))
    cli_selfhost_object_symbol_tests = cli_selfhost_object_symbol_tests.dep("build")
    out = out.add_target(cli_selfhost_object_symbol_tests)

    // D39 bundle interfaces: .wi flavor, --link-bundle, declaration-only
    // codegen (build/selfhost.w bs_check_bundle_interface).
    var bundle_interface_tests = target_new(.Action, "bundle-interface-tests", "").output("out/test-graph/bundle-interface-tests")
    bundle_interface_tests = bundle_interface_tests.allow_parallel()
    bundle_interface_tests.action = run_bundle_interface_action
    bundle_interface_tests = bundle_interface_tests.arg("nm")
    bundle_interface_tests = bundle_interface_tests.input(release_compiler_bin("with"))
    bundle_interface_tests = bundle_interface_tests.input("test/bundle_interface/lib/std/wi_demo.w")
    bundle_interface_tests = bundle_interface_tests.input("test/bundle_interface/wi_demo.wi")
    bundle_interface_tests = bundle_interface_tests.input("test/bundle_interface/main.w")
    bundle_interface_tests = bundle_interface_tests.input("test/bundle_interface/bad_elision.wi")
    bundle_interface_tests = bundle_interface_tests.input("test/bundle_interface/lib/std/wi_omit_generic.w")
    bundle_interface_tests = bundle_interface_tests.input("test/bundle_interface/lib/std/wi_refuse_drop.w")
    bundle_interface_tests = bundle_interface_tests.input("test/bundle_interface/lib/std/wi_refuse_const.w")
    bundle_interface_tests = bundle_interface_tests.input("test/bundle_interface/lib/std/wi_refuse_elision.w")
    bundle_interface_tests = bundle_interface_tests.input("test/bundle_interface/body_in_wi.wi")
    bundle_interface_tests = bundle_interface_tests.input("test/bundle_interface/init_in_wi.wi")
    bundle_interface_tests = bundle_interface_tests.dep("build")
    out = out.add_target(bundle_interface_tests)

    var cli_selfhost_build_w_tests = target_new(.Action, "cli-selfhost-build-w-tests", "").output("out/test-graph/cli-selfhost-build-w-tests")
    cli_selfhost_build_w_tests = cli_selfhost_build_w_tests.allow_parallel()
    cli_selfhost_build_w_tests.action = run_cli_selfhost_build_w_action
    cli_selfhost_build_w_tests = cli_selfhost_build_w_tests.input(release_compiler_bin("with"))
    cli_selfhost_build_w_tests = cli_selfhost_build_w_tests.dep("build")
    out = out.add_target(cli_selfhost_build_w_tests)

    var cli_selfhost_project_tests = target_new(.Action, "cli-selfhost-project-tests", "").output("out/test-graph/cli-selfhost-project-tests")
    cli_selfhost_project_tests = cli_selfhost_project_tests.allow_parallel()
    cli_selfhost_project_tests.action = run_cli_selfhost_project_action
    cli_selfhost_project_tests = cli_selfhost_project_tests.input(release_compiler_bin("with"))
    cli_selfhost_project_tests = cli_selfhost_project_tests.allow_network()
    cli_selfhost_project_tests = cli_selfhost_project_tests.dep("build")
    out = out.add_target(cli_selfhost_project_tests)

    var cli_selfhost_lsp_tests = target_new(.Action, "cli-selfhost-lsp-tests", "").output("out/test-graph/cli-selfhost-lsp-tests")
    cli_selfhost_lsp_tests = cli_selfhost_lsp_tests.allow_parallel()
    cli_selfhost_lsp_tests.action = run_cli_selfhost_lsp_action
    cli_selfhost_lsp_tests = cli_selfhost_lsp_tests.input(release_compiler_bin("with"))
    cli_selfhost_lsp_tests = cli_selfhost_lsp_tests.dep("build")
    out = out.add_target(cli_selfhost_lsp_tests)

    var cli_selfhost_edge_tests = target_new(.Action, "cli-selfhost-edge-tests", "").output("out/test-graph/cli-selfhost-edge-tests")
    cli_selfhost_edge_tests.action = run_cli_selfhost_edge_action
    cli_selfhost_edge_tests = cli_selfhost_edge_tests.input(release_compiler_bin("with"))
    cli_selfhost_edge_tests = cli_selfhost_edge_tests.dep("build")
    out = out.add_target(cli_selfhost_edge_tests)

    var cli_selfhost_parallel_tests = target_new(.Action, "cli-selfhost-parallel-tests", "").output("out/test-graph/cli-selfhost-parallel-tests")
    cli_selfhost_parallel_tests.action = run_cli_selfhost_parallel_action
    cli_selfhost_parallel_tests = cli_selfhost_parallel_tests.input(release_compiler_bin("with"))
    cli_selfhost_parallel_tests = cli_selfhost_parallel_tests.dep("build")
    out = out.add_target(cli_selfhost_parallel_tests)

    var c_migrator_pcre2_prep_tests = target_new(.Action, "c-migrator-pcre2-prep-tests", "").output("out/test-graph/c-migrator-pcre2-prep-tests")
    c_migrator_pcre2_prep_tests.action = run_cli_selfhost_pcre2_prep_action
    c_migrator_pcre2_prep_tests = c_migrator_pcre2_prep_tests.input(release_compiler_bin("with"))
    c_migrator_pcre2_prep_tests = c_migrator_pcre2_prep_tests.dep("build")
    out = out.add_target(c_migrator_pcre2_prep_tests)

    var c_migrator_basic_tests = target_new(.Action, "c-migrator-basic-tests", "").output("out/test-graph/c-migrator-basic-tests")
    c_migrator_basic_tests.action = run_cli_selfhost_migrate_basic_action
    c_migrator_basic_tests = c_migrator_basic_tests.input(release_compiler_bin("with"))
    c_migrator_basic_tests = c_migrator_basic_tests.dep("build")
    out = out.add_target(c_migrator_basic_tests)

    var c_migrator_core_tests = target_new(.Action, "c-migrator-core-tests", "").output("out/test-graph/c-migrator-core-tests")
    c_migrator_core_tests.action = run_cli_selfhost_migrate_core_action
    c_migrator_core_tests = c_migrator_core_tests.input(release_compiler_bin("with"))
    c_migrator_core_tests = c_migrator_core_tests.dep("build")
    out = out.add_target(c_migrator_core_tests)

    var c_migrator_tests = target_new(.Group, "c-migrator-tests", "")
    c_migrator_tests = c_migrator_tests.dep("c-migrator-basic-tests")
    c_migrator_tests = c_migrator_tests.dep("c-migrator-core-tests")
    out = out.add_target(c_migrator_tests)

    var issue61_regression = target_new(.Action, "issue61-regression", "").output("out/test-graph/issue61-regression")
    issue61_regression = issue61_regression.allow_parallel()
    issue61_regression.action = issue61_regression_action
    issue61_regression = issue61_regression.input(release_compiler_bin("with"))
    issue61_regression = issue61_regression.dep("build")
    out = out.add_target(issue61_regression)

    let invariance_labels: Vec[str] = Vec.new()
    invariance_labels.push("comment-sema")
    invariance_labels.push("let-sema")
    invariance_labels.push("two-lets-sema")
    invariance_labels.push("let-parser")
    invariance_labels.push("let-main")
    var invariance_check = target_new(.Group, "invariance-check", "")
    for ii in 0..invariance_labels.len() as i32:
        let inv_label = invariance_labels.get(ii as i64)
        var inv = target_new(.Action, "invariance-" ++ inv_label, "").output("out/test-graph/invariance-" ++ inv_label)
        inv.action = invariance_variant_action
        inv = inv.input(release_compiler_bin("with"))
        inv = inv.arg(build_owned_text(inv_label))
        inv = inv.allow_parallel()
        inv = inv.dep("build")
        out = out.add_target(inv)
        invariance_check = invariance_check.dep("invariance-" ++ inv_label)
    out = out.add_target(invariance_check)

    var embedded_runtime_regression = target_new(.Action, "embedded-runtime-regression", "").output("out/test-graph/embedded-runtime-regression")
    embedded_runtime_regression = embedded_runtime_regression.allow_parallel()
    embedded_runtime_regression.action = run_embedded_runtime_regression_action
    embedded_runtime_regression = embedded_runtime_regression.input(release_compiler_bin("with"))
    embedded_runtime_regression = embedded_runtime_regression.dep("build")
    out = out.add_target(embedded_runtime_regression)

    var emit_c_smoke = target_new(.Action, "emit-c-smoke", "").output("out/test-graph/emit-c-smoke")
    emit_c_smoke.action = run_emit_c_smoke_action
    emit_c_smoke = emit_c_smoke.input(release_compiler_bin("with"))
    emit_c_smoke = emit_c_smoke.input("test/hello.w")
    emit_c_smoke = emit_c_smoke.dep("build")
    emit_c_smoke = emit_c_smoke.dep("runtime")
    out = out.add_target(emit_c_smoke)

    var test_green = target_new(.Action, "test-green", "").output("out/.build-state/test-green.json")
    test_green.action = run_test_green_action
    test_green = test_green.input(host_bin("out/bin/with-sha256"))
    test_green = test_green.write_scope("out/.build-state")
    test_green = test_green.write_scope("out/command/test-green")
    test_green = test_green.dep("with-sha256")
    out = out.add_target(test_green)

    var tests = target_new(.Group, "test", "")
    tests = tests.dep("behavior-tests")
    tests = tests.dep("native-compile-error-tests")
    tests = tests.dep("native-codegen-tests")
    tests = tests.dep("native-spec-tests")
    tests = tests.dep("native-phase-tests")
    tests = tests.dep("comptime-diff-tests")
    // Allocator lane in the standing battery: the drop-discipline "floor
    // eyes". First battery inclusion (2026-07-19) immediately caught
    // two-week-old fixture rot — a lane that exists but never runs is
    // silent debt. 14 s, input-keyed (skips when compiler+fixtures fresh).
    tests = tests.dep("debug-alloc-tests")
    tests = tests.dep("internals-tests")
    tests = tests.dep("lexer-tests")
    tests = tests.dep("parser-tests")
    tests = tests.dep("deep-debug-tool-tests")
    tests = tests.dep("abi-hash-check")
    tests = tests.dep("cli-selfhost-smoke-tests")
    tests = tests.dep("cli-selfhost-one-liner-tests")
    tests = tests.dep("cli-selfhost-fmt-tests")
    tests = tests.dep("cli-selfhost-object-symbol-tests")
    tests = tests.dep("bundle-interface-tests")
    tests = tests.dep("cli-selfhost-build-w-tests")
    tests = tests.dep("cli-selfhost-project-tests")
    tests = tests.dep("cli-selfhost-lsp-tests")
    tests = tests.dep("cli-selfhost-edge-tests")
    tests = tests.dep("cli-selfhost-parallel-tests")
    tests = tests.dep("c-migrator-tests")
    tests = tests.dep("issue61-regression")
    tests = tests.dep("invariance-check")
    tests = tests.dep("embedded-runtime-regression")
    tests = tests.dep("emit-c-smoke")
    tests = tests.dep("requirements-informative-check")
    tests = tests.dep("spec-inventory-check")
    tests = tests.dep("test-green")
    out = out.add_target(tests)

    var last_green = target_new(.Action, "last-green", "").output("out/.build-state/last-green.json")
    last_green.action = run_last_green_action
    // D19: last-green is pure evidence assembly — it reads what test-green
    // and fixpoint-evidence recorded and fails loudly when stale. It must
    // never trigger rebuilds of the things it is blessing, so it carries no
    // deps on the build/fixpoint targets.
    last_green = last_green.input(host_bin("out/bin/with-sha256"))
    last_green = last_green.input(release_compiler_bin("with"))
    last_green = last_green.input("out/.build-state/seed-input.json")
    last_green = last_green.input("src/version")
    last_green = last_green.extra_output("out/seed-archive")
    last_green = last_green.extra_output("out/command/last-green")
    last_green = last_green.write_scope("out/.build-state")
    last_green = last_green.write_scope("out/seed-archive")
    last_green = last_green.write_scope("out/command/last-green")
    last_green = last_green.dep("with-sha256")
    out = out.add_target(last_green)

    var require_last_green = target_new(.Action, "require-last-green", "").output("out/command/require-last-green/ok")
    require_last_green.action = run_require_last_green_action
    require_last_green = require_last_green.input(host_bin("out/bin/with-sha256"))
    require_last_green = require_last_green.write_scope("out/command/require-last-green")
    require_last_green = require_last_green.dep("with-sha256")
    out = out.add_target(require_last_green)

    if release_platform_asset_is_distinct():
        var release_platform_asset = target_new(.Action, "release-platform-asset", "").output(release_platform_asset_bin())
        release_platform_asset.action = run_release_platform_asset_action
        release_platform_asset = release_platform_asset.input(release_compiler_bin("with"))
        release_platform_asset = release_platform_asset.write_scope("out/release")
        release_platform_asset = release_platform_asset.dep("build")
        out = out.add_target(release_platform_asset)

    var release_artifact_smoke_uat = target_new(.Action, "release-artifact-smoke-uat", "").output("out/release-uat/artifact-smoke.passed")
    release_artifact_smoke_uat.action = run_release_artifact_smoke_uat_action
    release_artifact_smoke_uat = release_artifact_smoke_uat.input(release_platform_asset_bin())
    release_artifact_smoke_uat = release_artifact_smoke_uat.write_scope("out/release-uat")
    release_artifact_smoke_uat = release_artifact_smoke_uat.dep("require-last-green")
    release_artifact_smoke_uat = release_uat_platform_asset_dep(move release_artifact_smoke_uat)
    out = out.add_target(release_artifact_smoke_uat)

    var release_fresh_project_uat = target_new(.Action, "release-fresh-project-uat", "").output("out/release-uat/fresh-project.passed")
    release_fresh_project_uat.action = run_release_fresh_project_uat_action
    release_fresh_project_uat = release_fresh_project_uat.input(release_platform_asset_bin())
    release_fresh_project_uat = release_fresh_project_uat.write_scope("out/release-uat")
    release_fresh_project_uat = release_fresh_project_uat.dep("require-last-green")
    release_fresh_project_uat = release_uat_platform_asset_dep(move release_fresh_project_uat)
    out = out.add_target(release_fresh_project_uat)

    var release_migrate_uat = target_new(.Action, "release-migrate-uat", "").output("out/release-uat/migrate.passed")
    release_migrate_uat.action = run_release_migrate_uat_action
    release_migrate_uat = release_migrate_uat.input(release_platform_asset_bin())
    release_migrate_uat = release_migrate_uat.write_scope("out/release-uat")
    release_migrate_uat = release_migrate_uat.dep("require-last-green")
    release_migrate_uat = release_uat_platform_asset_dep(move release_migrate_uat)
    out = out.add_target(release_migrate_uat)

    var release_zlib_uat = target_new(.Action, "release-zlib-uat", "").output("out/release-uat/zlib.passed")
    release_zlib_uat.action = run_release_zlib_uat_action
    release_zlib_uat = release_zlib_uat.input(release_platform_asset_bin())
    release_zlib_uat = release_zlib_uat.input("build/release_uat_fixtures/zlib_main.w")
    release_zlib_uat = release_zlib_uat.write_scope("out/release-uat")
    release_zlib_uat = release_zlib_uat.allow_network()
    release_zlib_uat = release_zlib_uat.dep("require-last-green")
    release_zlib_uat = release_uat_platform_asset_dep(move release_zlib_uat)
    out = out.add_target(release_zlib_uat)

    var release_bzip2_uat = target_new(.Action, "release-bzip2-uat", "").output("out/release-uat/bzip2.passed")
    release_bzip2_uat.action = run_release_bzip2_uat_action
    release_bzip2_uat = release_bzip2_uat.input(release_platform_asset_bin())
    release_bzip2_uat = release_bzip2_uat.input("build/release_uat_fixtures/bzip2_main.w")
    release_bzip2_uat = release_bzip2_uat.write_scope("out/release-uat")
    release_bzip2_uat = release_bzip2_uat.allow_network()
    release_bzip2_uat = release_bzip2_uat.dep("require-last-green")
    release_bzip2_uat = release_uat_platform_asset_dep(move release_bzip2_uat)
    out = out.add_target(release_bzip2_uat)

    var release_sqlite3_uat = target_new(.Action, "release-sqlite3-uat", "").output("out/release-uat/sqlite3.passed")
    release_sqlite3_uat.action = run_release_sqlite3_uat_action
    release_sqlite3_uat = release_sqlite3_uat.input(release_platform_asset_bin())
    release_sqlite3_uat = release_sqlite3_uat.input("build/release_uat_fixtures/sqlite3_main.w")
    release_sqlite3_uat = release_sqlite3_uat.write_scope("out/release-uat")
    release_sqlite3_uat = release_sqlite3_uat.allow_network()
    release_sqlite3_uat = release_sqlite3_uat.dep("require-last-green")
    release_sqlite3_uat = release_uat_platform_asset_dep(move release_sqlite3_uat)
    out = out.add_target(release_sqlite3_uat)

    var release_openssl_uat = target_new(.Action, "release-openssl-uat", "").output("out/release-uat/openssl.passed")
    release_openssl_uat.action = run_release_openssl_uat_action
    release_openssl_uat = release_openssl_uat.input(release_platform_asset_bin())
    release_openssl_uat = release_openssl_uat.input("build/release_uat_fixtures/openssl_main.w")
    release_openssl_uat = release_openssl_uat.write_scope("out/release-uat")
    release_openssl_uat = release_openssl_uat.allow_network()
    release_openssl_uat = release_openssl_uat.dep("require-last-green")
    release_openssl_uat = release_uat_platform_asset_dep(move release_openssl_uat)
    out = out.add_target(release_openssl_uat)

    var release_libcurl_uat = target_new(.Action, "release-libcurl-uat", "").output("out/release-uat/libcurl.passed")
    release_libcurl_uat.action = run_release_libcurl_uat_action
    release_libcurl_uat = release_libcurl_uat.input(release_platform_asset_bin())
    release_libcurl_uat = release_libcurl_uat.input("build/release_uat_fixtures/libcurl_main.w")
    release_libcurl_uat = release_libcurl_uat.write_scope("out/release-uat")
    release_libcurl_uat = release_libcurl_uat.allow_network()
    release_libcurl_uat = release_libcurl_uat.dep("require-last-green")
    release_libcurl_uat = release_uat_platform_asset_dep(move release_libcurl_uat)
    out = out.add_target(release_libcurl_uat)

    var release_install_layout_uat = target_new(.Action, "release-install-layout-uat", "").output("out/release-uat/install-layout.passed")
    release_install_layout_uat.action = run_release_install_layout_uat_action
    release_install_layout_uat = release_install_layout_uat.input(release_platform_asset_bin())
    release_install_layout_uat = release_install_layout_uat.write_scope("out/release-uat")
    release_install_layout_uat = release_install_layout_uat.dep("require-last-green")
    release_install_layout_uat = release_uat_platform_asset_dep(move release_install_layout_uat)
    out = out.add_target(release_install_layout_uat)

    var release_raylib_spiral_uat = target_new(.Action, "release-raylib-spiral-uat", "").output("out/release-uat/raylib-spiral.passed")
    release_raylib_spiral_uat.action = run_release_raylib_spiral_uat_action
    release_raylib_spiral_uat = release_raylib_spiral_uat.input(release_platform_asset_bin())
    release_raylib_spiral_uat = release_raylib_spiral_uat.input("build/release_uat_fixtures/raylib_spiral_main.w")
    release_raylib_spiral_uat = release_raylib_spiral_uat.write_scope("out/release-uat")
    release_raylib_spiral_uat = release_raylib_spiral_uat.allow_network()
    release_raylib_spiral_uat = release_raylib_spiral_uat.dep("require-last-green")
    release_raylib_spiral_uat = release_uat_platform_asset_dep(move release_raylib_spiral_uat)
    out = out.add_target(release_raylib_spiral_uat)

    var release_one_liner_uat = target_new(.Action, "release-one-liner-uat", "").output("out/release-uat/one-liners.passed")
    release_one_liner_uat.action = run_release_one_liner_uat_action
    release_one_liner_uat = release_one_liner_uat.input(release_platform_asset_bin())
    release_one_liner_uat = release_one_liner_uat.write_scope("out/release-uat")
    release_one_liner_uat = release_one_liner_uat.dep("require-last-green")
    release_one_liner_uat = release_uat_platform_asset_dep(move release_one_liner_uat)
    out = out.add_target(release_one_liner_uat)

    var release_uat = target_new(.Group, "release-uat", "")
    release_uat = release_uat.dep("release-artifact-smoke-uat")
    release_uat = release_uat.dep("release-fresh-project-uat")
    release_uat = release_uat.dep("release-migrate-uat")
    release_uat = release_uat.dep("release-zlib-uat")
    release_uat = release_uat.dep("release-bzip2-uat")
    release_uat = release_uat.dep("release-sqlite3-uat")
    release_uat = release_uat.dep("release-openssl-uat")
    release_uat = release_uat.dep("release-libcurl-uat")
    release_uat = release_uat.dep("release-install-layout-uat")
    release_uat = release_uat.dep("release-raylib-spiral-uat")
    release_uat = release_uat.dep("release-one-liner-uat")
    out = out.add_target(release_uat)

    var check_committed = target_new(.Action, "check-committed-state", "").output("out/command/check-committed-state/ok")
    check_committed.action = run_check_committed_state_action
    check_committed = check_committed.write_scope("out/command/check-committed-state")
    out = out.add_target(check_committed)

    out = out.add_target(install_file_target("install-user", release_compiler_bin("with"), "$HOME/.local/bin/with", "0755", "require-last-green"))

    out = out.add_target(install_file_target("install-compiler", release_compiler_bin("with"), "$INSTALL_BINDIR/with" ++ host_exe_suffix(), "0755", "build"))
    out = out.add_target(install_file_target("install-rt-core", "out/lib/rt_core.o", "$INSTALL_LIBDIR/rt_core.o", "0644", "runtime"))
    out = out.add_target(install_file_target("install-rt-platform", host_runtime.platform_object, "$INSTALL_LIBDIR/" ++ host_runtime.platform_install_object, "0644", "runtime"))
    out = out.add_target(install_file_target("install-cimport-stubs", "out/lib/cimport_stubs.o", "$INSTALL_LIBDIR/cimport_stubs.o", "0644", "runtime"))
    out = out.add_target(install_file_target("install-compat-runtime", "out/lib/compat_runtime.o", "$INSTALL_LIBDIR/compat_runtime.o", "0644", "runtime"))
    out = out.add_target(install_file_target("install-panic-runtime", "out/lib/panic_runtime.o", "$INSTALL_LIBDIR/panic_runtime.o", "0644", "runtime"))
    out = out.add_target(install_file_target("install-regex-runtime", "out/lib/regex_runtime.o", "$INSTALL_LIBDIR/regex_runtime.o", "0644", "runtime"))
    out = out.add_target(install_file_target("install-fiber-stubs", "out/lib/fiber_stubs.o", "$INSTALL_LIBDIR/fiber_stubs.o", "0644", "runtime"))
    out = out.add_target(install_file_target("install-channel-runtime", "out/lib/channel_runtime.o", "$INSTALL_LIBDIR/channel_runtime.o", "0644", "runtime"))
    out = out.add_target(install_file_target("install-fiber-runtime", "out/lib/fiber_runtime.o", "$INSTALL_LIBDIR/fiber_runtime.o", "0644", "runtime"))
    out = out.add_target(install_file_target("install-fiber-core", "out/lib/fiber.o", "$INSTALL_LIBDIR/fiber.o", "0644", "runtime"))
    out = out.add_target(install_file_target("install-fiber-asm", "out/lib/fiber_asm.o", "$INSTALL_LIBDIR/fiber_asm.o", "0644", "runtime"))
    out = out.add_target(install_file_target("install-embedded-objects", "out/lib/embedded_objects.o", "$INSTALL_LIBDIR/embedded_objects.o", "0644", "runtime"))
    out = out.add_target(install_file_target("install-embedded-objects-asm", "out/lib/embedded_objects.s", "$INSTALL_LIBDIR/embedded_objects.s", "0644", "runtime"))
    out = out.add_target(install_file_target("install-llvm-bridge", "out/lib/llvm_bridge.o", "$INSTALL_LIBDIR/llvm_bridge.o", "0644", "llvm-link-metadata"))
    out = out.add_target(install_file_target("install-clang-bridge", "out/lib/clang_bridge.o", "$INSTALL_LIBDIR/clang_bridge.o", "0644", "llvm-link-metadata"))
    out = out.add_target(install_file_target("install-llvm-link-rsp", "out/lib/llvm_link.rsp", "$INSTALL_LIBDIR/llvm_link.rsp", "0644", "llvm-link-metadata"))
    out = out.add_target(install_file_target("install-llvm-cc", "out/lib/llvm_cc", "$INSTALL_LIBDIR/llvm_cc", "0644", "llvm-link-metadata"))
    out = out.add_target(install_file_target("install-llvm-ld-rsp", "out/lib/llvm_ld.rsp", "$INSTALL_LIBDIR/llvm_ld.rsp", "0644", "llvm-link-metadata"))
    out = out.add_target(install_file_target("install-llvm-ld", "out/lib/llvm_ld", "$INSTALL_LIBDIR/llvm_ld", "0644", "llvm-link-metadata"))
    var install = target_new(.Group, "install", "")
    install = install.dep("install-compiler")
    install = install.dep("install-rt-core")
    install = install.dep("install-rt-platform")
    install = install.dep("install-cimport-stubs")
    install = install.dep("install-compat-runtime")
    install = install.dep("install-panic-runtime")
    install = install.dep("install-regex-runtime")
    install = install.dep("install-fiber-stubs")
    install = install.dep("install-channel-runtime")
    install = install.dep("install-fiber-runtime")
    install = install.dep("install-fiber-core")
    install = install.dep("install-fiber-asm")
    install = install.dep("install-embedded-objects")
    install = install.dep("install-embedded-objects-asm")
    install = install.dep("install-llvm-bridge")
    install = install.dep("install-clang-bridge")
    install = install.dep("install-llvm-link-rsp")
    install = install.dep("install-llvm-cc")
    install = install.dep("install-llvm-ld-rsp")
    install = install.dep("install-llvm-ld")
    out = out.add_target(install)

    var seed = target_new(.Action, "seed", "").output("src/main")
    seed.action = run_seed_download_action
    seed = seed.input("build/https_fetch.w")
    seed = seed.write_scope("out/tmp")
    seed = seed.allow_network()
    seed = seed.arg("withlang-dev/with")
    seed = seed.arg(release_asset_for_host())
    out = out.add_target(seed)

    // `with build :deps` — fetch the pinned, per-platform static LLVM SDK that
    // bootstrap built and a release published, into `.deps/llvm-<ver>-<host>`,
    // so a build never rebuilds LLVM from source or trusts a system LLVM.
    var deps = target_new(.Action, "deps", "").output(compiler_default_libclang_archive_path())
    deps.action = run_deps_download_action
    deps = deps.input("build/https_fetch.w")
    deps = deps.input("build/zlib_gunzip.w")
    deps = deps.write_scope("out/tmp")
    deps = deps.write_scope(".deps")
    deps = deps.allow_network()
    deps = deps.arg("withlang-dev/with")
    deps = deps.arg(llvm_sdk_asset_for_host())
    deps = deps.arg(llvm_sdk_dir_basename())
    out = out.add_target(deps)

    var cross = target_new(.Action, "cross", "").output("out/command/cross/unsupported")
    cross.action = run_cross_unsupported_action
    cross = cross.arg(env("CROSS_TARGET"))
    cross = cross.write_scope("out/command/cross")
    out = out.add_target(cross)

    out = out.add_target(install_file_target("update-seed", release_compiler_bin("with"), "src/main", "0755", "require-last-green"))

    var clean = target_new(.Clean, "clean", "")
    clean = clean.arg("out")
    clean = clean.arg(".with")
    clean = clean.arg("src/main.c")
    clean = clean.arg("src/main.o")
    clean = clean.arg("src/bootstrap_main.c")
    clean = clean.arg("src/bootstrap_main.o")
    clean = clean.arg("main.c")
    clean = clean.arg("main.o")
    clean = clean.arg("bootstrap_main.c")
    clean = clean.arg("bootstrap_main.o")
    out = out.add_target(clean)

    var pcre2_reference = target_new(.Action, "pcre2-reference", "").output("out/pcre2_reference/pcre2-10.47")
    pcre2_reference.action = run_pcre2_reference_action
    pcre2_reference = pcre2_reference.extra_output("out/pcre2_reference/pcre2-10.47/.with-reference-ready")
    pcre2_reference = pcre2_reference.input("build/https_fetch.w")
    pcre2_reference = pcre2_reference.input("build/zlib_gunzip.w")
    pcre2_reference = pcre2_reference.write_scope("out/tmp/action-scratch/pcre2-reference")
    pcre2_reference = pcre2_reference.allow_network()
    pcre2_reference = pcre2_reference.arg("pcre2-10.47")
    pcre2_reference = pcre2_reference.arg("https://github.com/PCRE2Project/pcre2/releases/download/pcre2-10.47/pcre2-10.47.tar.gz")
    out = out.add_target(pcre2_reference)

    var pcre2_migrate = target_new(.Action, "pcre2-migrate", "").output("out/gen/.regex-migrate-stamp")
    pcre2_migrate.action = run_pcre2_migrate_action
    pcre2_migrate = pcre2_migrate.extra_output("out/pcre2_migrated")
    pcre2_migrate = pcre2_migrate.write_scope("out/tmp/action-scratch/pcre2-migrate")
    pcre2_migrate = pcre2_migrate.write_scope("out/pcre2_migrate_raw")
    pcre2_migrate = pcre2_migrate.write_scope("out/pcre2_generated")
    pcre2_migrate = pcre2_migrate.write_scope("out/pcre2_build")
    pcre2_migrate = pcre2_migrate.write_scope("out/gen/.regex-build-stamp")
    pcre2_migrate = pcre2_migrate.input("out/pcre2_reference/pcre2-10.47/src")
    pcre2_migrate = pcre2_migrate.arg("out/pcre2_migrated")
    pcre2_migrate = pcre2_migrate.arg("pcre2demo.c")
    pcre2_migrate = pcre2_migrate.arg("pcre2grep.c")
    pcre2_migrate = pcre2_migrate.arg("pcre2posix_test.c")
    pcre2_migrate = pcre2_migrate.arg("pcre2_jit_test.c")
    pcre2_migrate = pcre2_migrate.arg("pcre2_dftables.c")
    pcre2_migrate = pcre2_migrate.arg("pcre2_fuzzsupport.c")
    pcre2_migrate = pcre2_migrate.dep("pcre2-reference")
    out = out.add_target(pcre2_migrate)

    var pcre2_migrate_smoke = target_new(.Action, "pcre2-migrate-smoke", "").output("out/test-graph/pcre2-migrate-smoke")
    pcre2_migrate_smoke.action = run_pcre2_migrate_smoke_action
    pcre2_migrate_smoke = pcre2_migrate_smoke.input("out/pcre2_reference/pcre2-10.47/src/pcre2_compile.c")
    pcre2_migrate_smoke = pcre2_migrate_smoke.input("out/pcre2_reference/pcre2-10.47/src")
    pcre2_migrate_smoke = pcre2_migrate_smoke.dep("pcre2-reference")
    out = out.add_target(pcre2_migrate_smoke)

    var pcre2_test_smoke = target_new(.Action, "pcre2-test-smoke", "").output("out/test-graph/pcre2-test-smoke")
    pcre2_test_smoke.action = run_pcre2_test_smoke_action
    pcre2_test_smoke = pcre2_test_smoke.input("lib/std/re/pcre2test.w")
    pcre2_test_smoke = pcre2_test_smoke.input("out/pcre2_reference/pcre2-10.47/RunTest")
    pcre2_test_smoke = pcre2_test_smoke.arg("out/pcre2_reference/pcre2-10.47")
    pcre2_test_smoke = pcre2_test_smoke.dep("pcre2-reference")
    pcre2_test_smoke = pcre2_test_smoke.dep("selfcheck")
    out = out.add_target(pcre2_test_smoke)

    var pcre2_build = target_new(.Action, "pcre2-build", "").output("out/pcre2_build")
    pcre2_build.action = run_pcre2_build_action
    pcre2_build = pcre2_build.write_scope("out/tmp/action-scratch/pcre2-build")
    pcre2_build = pcre2_build.input("out/pcre2_migrated")
    pcre2_build = pcre2_build.dep("build")
    pcre2_build = pcre2_build.dep("pcre2-migrate")
    out = out.add_target(pcre2_build)

    var pcre2_test = target_new(.Action, "pcre2-test", "").output("out/corpus/pcre2-test")
    pcre2_test.action = run_pcre2_test_action
    pcre2_test = pcre2_test.input("out/pcre2_migrated")
    pcre2_test = pcre2_test.input("out/pcre2_build/bin/pcre2test")
    pcre2_test = pcre2_test.input("out/pcre2_reference/pcre2-10.47/RunTest")
    pcre2_test = pcre2_test.arg("out/pcre2_reference/pcre2-10.47")
    pcre2_test = pcre2_test.dep("verified-existing-stage")
    // The declared inputs above are produced by pcre2-migrate / pcre2-build;
    // without these edges a clean out/ fails with "missing declared input"
    // before anything migrates (the zlib chain already had them).
    pcre2_test = pcre2_test.dep("pcre2-build")
    out = out.add_target(pcre2_test)

    var pcre2_check_generated = target_new(.Action, "pcre2-check-generated", "").output("out/gen/.pcre2-check-generated-stamp")
    pcre2_check_generated.action = run_pcre2_check_generated_action
    pcre2_check_generated = pcre2_check_generated.write_scope("out/tmp/action-scratch/pcre2-check-generated")
    pcre2_check_generated = pcre2_check_generated.input("out/pcre2_build/lib/std/re")
    pcre2_check_generated = pcre2_check_generated.dep("build")
    out = out.add_target(pcre2_check_generated)

    var pcre2_promote = target_new(.Action, "pcre2-promote", "").output("lib/std/re")
    pcre2_promote.action = run_pcre2_promote_action
    pcre2_promote = pcre2_promote.write_scope("out/tmp/action-scratch/pcre2-promote")
    pcre2_promote = pcre2_promote.input("out/pcre2_build/lib/std/re")
    pcre2_promote = pcre2_promote.dep("pcre2-test")
    out = out.add_target(pcre2_promote)

    var zlib_reference = target_new(.Action, "zlib-reference", "").output("out/zlib_reference/zlib-1.3.2")
    zlib_reference.action = run_zlib_reference_action
    zlib_reference = zlib_reference.extra_output("out/zlib_reference/zlib-1.3.2/.with-reference-ready")
    zlib_reference = zlib_reference.write_scope("out/tmp/action-scratch/zlib-reference")
    zlib_reference = zlib_reference.input("build/zlib_http_fetch.w")
    zlib_reference = zlib_reference.input("build/zlib_gunzip.w")
    zlib_reference = zlib_reference.arg("zlib-1.3.2")
    zlib_reference = zlib_reference.arg("http://zlib.net/fossils/zlib-1.3.2.tar.gz")
    zlib_reference = zlib_reference.allow_network()
    zlib_reference = zlib_reference.dep("runtime")
    out = out.add_target(zlib_reference)

    var zlib_migrate = target_new(.Action, "zlib-migrate", "").output("out/gen/.zlib-migrate-stamp")
    zlib_migrate.action = run_zlib_migrate_action
    zlib_migrate = zlib_migrate.extra_output("out/zlib_migrated")
    zlib_migrate = zlib_migrate.write_scope("out/tmp/action-scratch/zlib-migrate")
    zlib_migrate = zlib_migrate.write_scope("out/zlib_migrated")
    zlib_migrate = zlib_migrate.write_scope("out/zlib_build")
    zlib_migrate = zlib_migrate.write_scope("out/corpus/zlib-test")
    zlib_migrate = zlib_migrate.input("out/zlib_reference/zlib-1.3.2")
    zlib_migrate = zlib_migrate.arg("out/zlib_migrated")
    zlib_migrate = zlib_migrate.dep("zlib-reference")
    out = out.add_target(zlib_migrate)

    var zlib_build = target_new(.Action, "zlib-build", "").output("out/zlib_build")
    zlib_build.action = run_zlib_build_action
    zlib_build = zlib_build.write_scope("out/tmp/action-scratch/zlib-build")
    zlib_build = zlib_build.input("out/zlib_migrated")
    zlib_build = zlib_build.dep("build")
    zlib_build = zlib_build.dep("zlib-migrate")
    out = out.add_target(zlib_build)

    var zlib_test = target_new(.Action, "zlib-test", "").output("out/corpus/zlib-test")
    zlib_test.action = run_zlib_test_action
    zlib_test = zlib_test.input("out/zlib_migrated")
    zlib_test = zlib_test.input("out/zlib_build/bin/zlib_example")
    zlib_test = zlib_test.input("out/zlib_build/bin/minigzip")
    zlib_test = zlib_test.dep("zlib-build")
    out = out.add_target(zlib_test)

    var zlib_check_generated = target_new(.Action, "zlib-check-generated", "").output("out/gen/.zlib-check-generated-stamp")
    zlib_check_generated.action = run_zlib_check_generated_action
    zlib_check_generated = zlib_check_generated.write_scope("out/tmp/action-scratch/zlib-check-generated")
    zlib_check_generated = zlib_check_generated.input("out/zlib_migrated")
    zlib_check_generated = zlib_check_generated.dep("zlib-migrate")
    out = out.add_target(zlib_check_generated)

    var zlib_promote = target_new(.Action, "zlib-promote", "").output("lib/std/zlib")
    zlib_promote.action = run_zlib_promote_action
    zlib_promote = zlib_promote.write_scope("out/tmp/action-scratch/zlib-promote")
    zlib_promote = zlib_promote.input("out/zlib_migrated")
    zlib_promote = zlib_promote.dep("zlib-test")
    out = out.add_target(zlib_promote)

    var prune = target_new(.Action, "prune", "").output("out/.build-state/prune.always")
    prune.action = run_prune_action
    prune = prune.arg("dry-run")
    prune = prune.arg("live-target=prune")
    prune = prune.arg("live-target=prune-apply")
    prune = target_with_live_targets(move prune, out)
    prune = prune.write_scope("out/bin")
    prune = prune.write_scope("out/bootstrap/bin")
    prune = prune.write_scope("out/stage/bin")
    prune = prune.write_scope("out/release/bin")
    prune = prune.write_scope("out/lib")
    prune = prune.write_scope("out/bootstrap-lib")
    prune = prune.write_scope("out/.build-state")
    prune = prune.write_scope("out/seed-archive")
    prune = prune.write_scope("out/release")
    prune = prune.write_scope("out/test-graph")
    prune = prune.write_scope("out/command/prune")
    out = out.add_target(prune)

    var prune_apply = target_new(.Action, "prune-apply", "").output("out/.build-state/prune-apply.always")
    prune_apply.action = run_prune_action
    prune_apply = prune_apply.arg("apply")
    prune_apply = prune_apply.arg("live-target=prune")
    prune_apply = prune_apply.arg("live-target=prune-apply")
    prune_apply = target_with_live_targets(move prune_apply, out)
    prune_apply = prune_apply.write_scope("out/bin")
    prune_apply = prune_apply.write_scope("out/bootstrap/bin")
    prune_apply = prune_apply.write_scope("out/stage/bin")
    prune_apply = prune_apply.write_scope("out/release/bin")
    prune_apply = prune_apply.write_scope("out/lib")
    prune_apply = prune_apply.write_scope("out/bootstrap-lib")
    prune_apply = prune_apply.write_scope("out/.build-state")
    prune_apply = prune_apply.write_scope("out/seed-archive")
    prune_apply = prune_apply.write_scope("out/release")
    prune_apply = prune_apply.write_scope("out/test-graph")
    prune_apply = prune_apply.write_scope("out/command/prune-apply")
    out = out.add_target(prune_apply)

    // Keep the seed-built helper last until every public seed carries the
    // borrowed target lookup. Older seeds invalidate earlier non-Copy graph
    // entries while selecting a late default target.
    var sha256_tool = target_new(.Executable, "with-sha256", "tools/with-sha256.w").output(host_bin("out/bin/with-sha256"))
    sha256_tool = sha256_tool.compiler("seed")
    sha256_tool = sha256_tool.dep("prepare-bootstrap-link-root")
    out = out.add_target(move sha256_tool)

    out.default("build")
