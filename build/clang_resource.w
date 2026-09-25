module build.clang_resource

// Generates out/gen/compiler/EmbeddedClangResourceData.w from the static SDK's
// clang builtin headers (lib/clang/<v>/include), so the shipped binary serves
// clang's resource dir from inside itself instead of an external LLVM (#312).
//
// We embed only the C/POSIX builtin headers a c_import realistically needs
// (~156 KB), not the ~15 MB of SIMD-intrinsic / CUDA / HIP / SPIRV headers, to
// keep the shipped binary lean. WITH_CLANG_RESOURCE_DIR remains an explicit
// override for the rare header that needs the full set.

use std.build
use build.compiler
fn clang_resource_owned_text(s: &str): s ++ ""

fn cr_fail(ctx: &ActionCtx, message: &str) -> i32:
    ctx.diagnostics().error("embedded-clang-resource: " ++ message)

fn cr_dirname(path: &str) -> str:
    var last = -1
    for i in 0..path.len() as i32:
        let ch = path[i]
        if ch == 47 or ch == 92:
            last = i
    if last <= 0:
        return "."
    path.slice(0, last as i64)

fn cr_basename(path: &str) -> str:
    var last = -1
    for i in 0..path.len() as i32:
        let ch = path[i]
        if ch == 47 or ch == 92:
            last = i
    if last < 0:
        return clang_resource_owned_text(path)
    path.slice((last + 1) as i64, path.len())

fn cr_normalize_path_separators(path: &str) -> str:
    var out = ""
    for i in 0..path.len() as i32:
        let ch = path[i]
        if ch == 92:
            out = out ++ "/"
        else:
            out = out ++ path.slice(i as i64, (i + 1) as i64)
    out

fn cr_str_compare(a: &str, b: &str) -> i32:
    let n = if a.len() < b.len(): a.len() else: b.len()
    var i = 0
    while i < n as i32:
        let ac = a[i] as i32
        let bc = b[i] as i32
        if ac != bc:
            return ac - bc
        i = i + 1
    if a.len() == b.len():
        return 0
    if a.len() < b.len():
        return -1
    1

fn cr_sorted(files: &Vec[str]) -> Vec[str]:
    var sorted: Vec[str] = Vec.new()
    for i in 0..files.len() as i32:
        let path = files[i]
        var inserted = false
        var out: Vec[str] = Vec.new()
        for j in 0..sorted.len() as i32:
            let existing = sorted[j]
            if not inserted and cr_str_compare(path, existing) < 0:
                out.push(clang_resource_owned_text(path))
                inserted = true
            out.push(clang_resource_owned_text(existing))
        if not inserted:
            out.push(clang_resource_owned_text(path))
        sorted = out
    sorted

fn cr_contains_delimiter(text: &str, hashes: &str) -> bool:
    let needle = "\"" ++ hashes
    if text.len() < needle.len():
        return false
    var i = 0
    while i <= text.len() as i32 - needle.len() as i32:
        var j = 0
        var matched = true
        while j < needle.len() as i32:
            if text[(i + j)] != needle[j]:
                matched = false
                break
            j = j + 1
        if matched:
            return true
        i = i + 1
    false

fn cr_raw_string_literal(text: &str) -> str:
    var hashes = ""
    while cr_contains_delimiter(text, hashes):
        hashes = hashes ++ "#"
    "r" ++ hashes ++ "\"" ++ text ++ "\"" ++ hashes

// We embed the C/POSIX builtin headers a c_import realistically needs, NOT the
// full ~15 MB tree. The bulk of the full tree is SIMD/GPU intrinsics for every
// architecture (arm_neon 3 MB, arm_sve, arm_mve, opencl-c, altivec, …), and a
// 15 MB generated module is ~46x the working embedded-stdlib data — the seed's
// comptime evaluator is SIGKILL'd building a string that large. The subset is
// ~156 KB. WITH_CLANG_RESOURCE_DIR overrides for the rare header outside it.
fn cr_should_embed(name: &str) -> bool:
    if name.ends_with(".modulemap"):
        return true
    if name.starts_with("__stddef_") and name.ends_with(".h"):
        return true
    if name.starts_with("__stdarg_") and name.ends_with(".h"):
        return true
    // clang 22 split float.h into these parts.
    if name.starts_with("__float_") and name.ends_with(".h"):
        return true
    if name == "stddef.h" or name == "stdarg.h" or name == "stdint.h" or name == "stdbool.h":
        return true
    if name == "stdalign.h" or name == "stdnoreturn.h" or name == "stdatomic.h" or name == "stdckdint.h":
        return true
    if name == "limits.h" or name == "float.h" or name == "iso646.h" or name == "varargs.h":
        return true
    if name == "tgmath.h" or name == "inttypes.h" or name == "stdcountof.h" or name == "mm_malloc.h":
        return true
    cr_is_host_intrinsics(name)

// `with cc` compiles real C, and real C reaches for SIMD: raylib's
// stb_image_resize2.h includes <arm_neon.h>. A port builds for the host, so the
// host architecture's intrinsic headers are embedded (arm64 5.7 MB, x86_64
// 4.2 MB); the other architectures', and Arm's M-profile ones (MVE, CDE), are
// not.
fn cr_is_host_intrinsics(name: &str) -> bool:
    if not name.ends_with(".h"): return false
    if arch() == "aarch64" or arch() == "arm64":
        return (name.starts_with("arm_") and name != "arm_mve.h" and name != "arm_cde.h") or name == "arm64intr.h"
    if arch() == "x86_64":
        return name.ends_with("intrin.h") or name == "cpuid.h" or name == "mm3dnow.h" or name == "immintrin.h"
    false

// The name a `#include` / `#include_next` line asks for, or "". Written with
// indexing and slice only: on the linux-aarch64 leg the pinned seed evaluates
// this action at comptime, where str.trim is not available.
fn cr_included_name(line: &str) -> str:
    let n = line.len() as i32
    var i = 0
    while i < n and (line[i] == 32 or line[i] == 9):
        i = i + 1
    if i >= n or line[i] != 35:
        return ""
    i = i + 1
    while i < n and (line[i] == 32 or line[i] == 9):
        i = i + 1
    if not line.slice(i as i64, n as i64).starts_with("include"):
        return ""
    // The opening `<` or `"`, then up to its closing partner.
    while i < n and line[i] != 60 and line[i] != 34:
        i = i + 1
    if i >= n:
        return ""
    let close = if line[i] == 60: 62 else: 34
    let start = i + 1
    var end = start
    while end < n and line[end] != close:
        end = end + 1
    if end >= n:
        return ""
    line.slice(start as i64, end as i64)

// Path relative to the include dir, preserving subdirectories.
fn cr_relpath(path: &str, base: &str) -> str:
    let prefix = base ++ "/"
    if path.starts_with(prefix):
        return path.slice(prefix.len(), path.len())
    cr_basename(path)

// Find <prefix>/lib/clang/<n>/include by scanning for a listed file under it.
fn cr_find_include_dir(ctx: &ActionCtx) -> str:
    // Must be the in-project .deps path (relative): the build's ToolFs sandbox
    // refuses list_files on absolute paths outside the project root, so the SDK
    // is read from .deps (populated by `with build :deps`), not an external
    // LLVM_PREFIX. The link step may still use an absolute LLVM_PREFIX.
    let prefix = compiler_default_llvm_prefix()
    let clang_root = prefix ++ "/lib/clang"
    let all = ctx.fs().list_files(clang_root)
    for i in 0..all.len() as i32:
        let path = cr_normalize_path_separators(all[i])
        let marker = "/include/"
        var pos = -1
        var k = 0
        while k <= path.len() as i32 - marker.len() as i32:
            if path.slice(k as i64, (k + marker.len() as i32) as i64) == marker:
                pos = k
                break
            k = k + 1
        if pos >= 0:
            return path.slice(0, (pos + marker.len() as i32 - 1) as i64)
    ""

fn cr_generate(ctx: &ActionCtx, include_dir: &str, files: &Vec[str], version: &str) -> str:
    let fs = ctx.fs()
    var out = "// Auto-generated by with build embedded-clang-resource-source.\n"
    out = out ++ "// Do not edit by hand.\n\n"
    var listing = ""
    for i in 0..files.len() as i32:
        let path = files[i]
        let rel = cr_relpath(path, include_dir)
        let source = fs.read_text(path)
        if source.len() > 16000000:
            ctx.diagnostics().error("embedded-clang-resource: header too large: " ++ path)
        let sym = f"CLANG_RES_{i}"
        out = out ++ "let " ++ sym ++ ": str = " ++ cr_raw_string_literal(source) ++ "\n"
        if listing.len() > 0:
            listing = listing ++ "\n"
        listing = listing ++ rel
    out = out ++ "let CLANG_RES_LIST: str = " ++ cr_raw_string_literal(listing) ++ "\n"
    out = out ++ "let CLANG_RES_VERSION: str = " ++ cr_raw_string_literal(version) ++ "\n\n"
    out = out ++ "pub fn embedded_clang_resource_list() -> str:\n    return CLANG_RES_LIST.clone()\n\n"
    out = out ++ "pub fn embedded_clang_resource_version() -> str:\n    return CLANG_RES_VERSION.clone()\n\n"
    // Whether this compiler links clang's driver (`with cc`): the SDK has the
    // archive, or it predates it and with_clang_main is aliased to a stand-in
    // (build/compiler.w). An address comparison cannot tell: LLVM folds two
    // distinct function symbols to "not equal".
    // The same SDK, by the same path, that the compiler link tests.
    let lib_dir = comp_llvm_prefix_for_root(ctx.project_info().project_root()) ++ "/lib"
    let driver_linked = ctx.fs().host_exists(lib_dir ++ "/libclangMain.a") or ctx.fs().host_exists(lib_dir ++ "/clangMain.lib")
    out = out ++ "pub fn embedded_clang_driver_linked() -> bool:\n    return " ++ (if driver_linked: "true" else: "false") ++ "\n\n"
    // Whether this compiler links LLVM's WebAssembly backend (the wasm32
    // target): the SDK has the archive, or it predates it and the five
    // LLVMInitializeWebAssembly* entry points are aliased to a stand-in
    // (build/compiler.w comp_wasm_backend_alias_lines). The driver refuses a
    // wasm build from this fact before codegen starts.
    let wasm_backend_linked = comp_sdk_has_wasm_backend(ctx.fs(), lib_dir)
    out = out ++ "pub fn embedded_llvm_wasm_backend_linked() -> bool:\n    return " ++ (if wasm_backend_linked: "true" else: "false") ++ "\n\n"
    out = out ++ "pub fn embedded_clang_resource_data(name: &str) -> str:\n"
    for i in 0..files.len() as i32:
        let rel = cr_relpath(files[i], include_dir)
        let sym = f"CLANG_RES_{i}"
        out = out ++ "    if name == " ++ cr_raw_string_literal(rel) ++ ":\n"
        out = out ++ "        return " ++ sym ++ ".clone()\n"
    out ++ "    return \"\"\n"

pub fn generate_embedded_clang_resource_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let output = ctx.output()
    if output.len() == 0:
        return cr_fail(ctx, "requires an output path")
    let include_dir = cr_find_include_dir(ctx)
    if include_dir.len() == 0:
        return cr_fail(ctx, "could not find clang builtin headers under " ++ compiler_default_llvm_prefix() ++ "/lib/clang; run `with build :deps` or build the SDK")
    // The clang resource version is the numeric dir name (e.g. "22").
    let version = cr_basename(cr_dirname(include_dir))
    // Embed the curated C/POSIX builtin headers (see cr_should_embed).
    let all = cr_sorted(fs.list_files(include_dir))
    let files: Vec[str] = Vec.new()
    for i in 0..all.len() as i32:
        let path = cr_normalize_path_separators(all[i])
        if cr_should_embed(cr_basename(path)):
            files.push(path)
    if files.len() == 0:
        return cr_fail(ctx, "found no C/POSIX builtin headers under " ++ include_dir)
    // Close the set under inclusion: an intrinsics umbrella pulls in siblings no
    // name rule lists (x86 intrin.h includes intrin0.h, immintrin.h dozens).
    // A header is added when an embedded one includes it and the SDK has it.
    var scanned = 0
    while scanned < files.len() as i32:
        let text = fs.read_text(files[scanned])
        for line in text.split("\n"):
            let name = cr_included_name(line)
            if name.len() == 0:
                continue
            let wanted = include_dir ++ "/" ++ name
            var have = false
            for k in 0..files.len() as i32:
                if files[k] == wanted:
                    have = true
            if have:
                continue
            for k in 0..all.len() as i32:
                if cr_normalize_path_separators(all[k]) == wanted:
                    files.push(wanted)
                    break
        scanned = scanned + 1
    let generated = cr_generate(ctx, include_dir, files, version)
    if generated.len() == 0:
        return 1
    if fs.mkdir_all(cr_dirname(output)) != 0:
        return cr_fail(ctx, "could not create output directory: " ++ cr_dirname(output))
    if fs.write_text(output, generated) != 0:
        return cr_fail(ctx, "could not write: " ++ output)
    print(f"embedded {files.len()} clang builtin headers (resource v{version})")
    0
