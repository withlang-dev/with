module build_compiler

use std.build
use std.process

const COMPILER_DEFAULT_LLVM_PREFIX: str = "/usr/local/llvm"

fn comp_fail(ctx: ActionCtx, message: str) -> i32:
    ctx.diagnostics().error(ctx.target_name() ++ ": " ++ message)
    1

fn comp_join(left: str, right: str) -> str:
    if left.len() == 0:
        return right
    if right.len() == 0:
        return left
    if left.ends_with("/"):
        return left ++ right
    left ++ "/" ++ right

fn comp_abs(root: str, path: str) -> str:
    if path.len() > 0 and path.byte_at(0) == 47:
        return path
    comp_join(root, path)

fn comp_dirname(path: str) -> str:
    var last_slash = -1
    for i in 0..path.len() as i32:
        if path.byte_at(i as i64) == 47:
            last_slash = i
    if last_slash < 0:
        return "."
    if last_slash == 0:
        return "/"
    path.slice(0, last_slash as i64)

fn comp_trim(text: str) -> str:
    var start = 0
    var end = text.len() as i32
    while start < end:
        let ch = text.byte_at(start as i64)
        if ch != 9 and ch != 10 and ch != 13 and ch != 32:
            break
        start = start + 1
    while end > start:
        let ch = text.byte_at((end - 1) as i64)
        if ch != 9 and ch != 10 and ch != 13 and ch != 32:
            break
        end = end - 1
    text.slice(start as i64, end as i64)

fn comp_first_trimmed_line(text: str) -> str:
    var end = text.len() as i32
    for i in 0..text.len() as i32:
        let ch = text.byte_at(i as i64)
        if ch == 10 or ch == 13:
            end = i
            break
    comp_trim(text.slice(0, end as i64))

fn comp_index_of(text: str, needle: str) -> i32:
    if needle.len() == 0:
        return 0
    if text.len() < needle.len():
        return -1
    let last = text.len() as i32 - needle.len() as i32
    for i in 0..(last + 1):
        var matched = true
        for j in 0..needle.len() as i32:
            if text.byte_at((i + j) as i64) != needle.byte_at(j as i64):
                matched = false
                break
        if matched:
            return i
    -1

fn comp_replace_all(text: str, needle: str, replacement: str) -> str:
    if needle.len() == 0:
        return text
    var out = ""
    var start = 0
    while start < text.len() as i32:
        let remaining = text.len() as i32 - start
        if remaining < needle.len() as i32:
            out = out ++ text.slice(start as i64, text.len())
            return out
        let at = comp_index_of(text.slice(start as i64, text.len()), needle)
        if at < 0:
            out = out ++ text.slice(start as i64, text.len())
            return out
        let matched_at = start + at
        out = out ++ text.slice(start as i64, matched_at as i64) ++ replacement
        start = matched_at + needle.len() as i32
    out

fn comp_split_whitespace(text: str) -> Vec[str]:
    let parts: Vec[str] = Vec.new()
    var start = -1
    for i in 0..text.len() as i32:
        let ch = text.byte_at(i as i64)
        let is_space = ch == 9 or ch == 10 or ch == 13 or ch == 32
        if is_space:
            if start >= 0:
                parts.push(text.slice(start as i64, i as i64))
                start = -1
        else if start < 0:
            start = i
    if start >= 0:
        parts.push(text.slice(start as i64, text.len()))
    parts

fn comp_capture_stdout(ctx: ActionCtx, label: str, argv: Vec[str], timeout_ms: i32) -> str:
    let fs = ctx.fs()
    let root = ctx.project_info().project_root()
    let capture_dir = comp_join("out/command", ctx.target_name())
    if fs.mkdir_all(capture_dir) != 0:
        return ""
    let stdout_path = comp_join(capture_dir, label ++ ".stdout")
    let stderr_path = comp_join(capture_dir, label ++ ".stderr")
    let result = ctx.process_runner().run_capture(argv, comp_abs(root, stdout_path), comp_abs(root, stderr_path), timeout_ms)
    if result.rc != 0:
        if result.stderr.len() > 0:
            ctx.diagnostics().error(result.stderr)
        let _remove_stdout_err = fs.remove_file(stdout_path)
        let _remove_stderr_err = fs.remove_file(stderr_path)
        return ""
    let _remove_stdout = fs.remove_file(stdout_path)
    let _remove_stderr = fs.remove_file(stderr_path)
    comp_trim(result.stdout)

fn comp_tool_from_env(primary: str, legacy: str, fallback: str) -> str:
    let explicit = env(primary)
    if explicit.len() > 0:
        return explicit
    let old = env(legacy)
    if old.len() > 0:
        return old
    fallback

fn comp_llvm_prefix() -> str:
    let prefix = env("LLVM_PREFIX")
    if prefix.len() > 0:
        return prefix
    COMPILER_DEFAULT_LLVM_PREFIX

fn comp_llvm_config_tool() -> str:
    comp_tool_from_env("WITH_LLVM_CONFIG", "LLVM_CONFIG", comp_llvm_prefix() ++ "/bin/llvm-config")

fn comp_llvm_clang_tool() -> str:
    comp_tool_from_env("WITH_LLVM_CC", "LLVM_CC", comp_llvm_prefix() ++ "/bin/clang")

fn comp_libclang_path() -> str:
    let explicit = env("WITH_LIBCLANG")
    if explicit.len() > 0:
        return explicit
    let legacy = env("LIBCLANG_FILE")
    if legacy.len() > 0:
        return legacy
    comp_llvm_prefix() ++ "/lib/libclang.dylib"

fn comp_host_sdk_path(ctx: ActionCtx) -> str:
    let sdkroot = env("SDKROOT")
    if sdkroot.len() > 0:
        return sdkroot
    var argv: Vec[str] = Vec.new()
    argv |> push("/usr/bin/xcrun")
    argv |> push("--show-sdk-path")
    comp_capture_stdout(ctx, "xcrun-sdk-path", argv, 30000)

fn comp_resolve_compiler_version(ctx: ActionCtx) -> str:
    let fs = ctx.fs()
    let root = ctx.project_info().project_root()
    let base = comp_first_trimmed_line(fs.read_text("src/version"))
    if base.len() == 0:
        return ""
    let override_version = env("WITH_VERSION")
    if override_version.len() > 0:
        return override_version
    var hash_argv: Vec[str] = Vec.new()
    hash_argv |> push("git")
    hash_argv |> push("-C")
    hash_argv |> push(root)
    hash_argv |> push("rev-parse")
    hash_argv |> push("--short=9")
    hash_argv |> push("HEAD")
    let short_hash = comp_capture_stdout(ctx, "git-hash", hash_argv, 30000)
    var count_argv: Vec[str] = Vec.new()
    count_argv |> push("git")
    count_argv |> push("-C")
    count_argv |> push(root)
    count_argv |> push("rev-list")
    count_argv |> push("--count")
    count_argv |> push("HEAD")
    let commit_count = comp_capture_stdout(ctx, "git-count", count_argv, 30000)
    if short_hash.len() > 0 and commit_count.len() > 0:
        return base ++ "-" ++ commit_count ++ "-g" ++ short_hash
    base

fn comp_write_versioned_source(ctx: ActionCtx, source: str, output: str, version: str) -> i32:
    let fs = ctx.fs()
    let text = fs.read_text(source)
    if text.len() == 0:
        return comp_fail(ctx, "could not read source: " ++ source)
    let output_dir = comp_dirname(output)
    if fs.mkdir_all(output_dir) != 0:
        return comp_fail(ctx, "could not create output directory: " ++ output_dir)
    let placeholder = "WITH_VERSION" ++ "_PLACEHOLDER"
    let replaced = comp_replace_all(text, placeholder, version)
    if fs.write_text(output, replaced) != 0:
        return comp_fail(ctx, "could not write: " ++ output)
    0

pub fn run_generate_compiler_entrypoints_action(ctx: ActionCtx) -> i32:
    let stamp_path = ctx.output()
    if stamp_path.len() == 0:
        return comp_fail(ctx, "requires a stamp output")
    let version = comp_resolve_compiler_version(ctx)
    if version.len() == 0:
        return comp_fail(ctx, "could not resolve compiler version from src/version")
    var rc = comp_write_versioned_source(ctx, "src/main.w", "out/gen/main.w", version)
    if rc != 0: return rc
    rc = comp_write_versioned_source(ctx, "src/bootstrap_main.w", "out/gen/bootstrap_main.w", version)
    if rc != 0: return rc
    rc = comp_write_versioned_source(ctx, "src/main_emit_temp.w", "out/gen/main_emit_temp.w", version)
    if rc != 0: return rc
    let fs = ctx.fs()
    if fs.write_text("out/gen/version.txt", version ++ "\n") != 0:
        return comp_fail(ctx, "could not write: out/gen/version.txt")
    if fs.write_text(stamp_path, version ++ "\n") != 0:
        return comp_fail(ctx, "could not write stamp: " ++ stamp_path)
    0

pub fn run_generate_llvm_link_metadata_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let output_path = ctx.output()
    if output_path.len() == 0:
        return comp_fail(ctx, "requires a stamp output path")
    let output_dir = comp_dirname(output_path)
    if fs.mkdir_all(output_dir) != 0:
        return comp_fail(ctx, "could not create output directory: " ++ output_dir)
    let inputs = ctx.inputs()
    for ii in 0..inputs.len() as i32:
        let input_path = inputs.get(ii as i64)
        if not fs.exists(input_path):
            return comp_fail(ctx, "missing input: " ++ input_path)
    let llvm_config = comp_llvm_config_tool()
    let llvm_clang = comp_llvm_clang_tool()
    let libclang = comp_libclang_path()
    if not fs.host_exists(llvm_config):
        return comp_fail(ctx, "missing llvm-config: " ++ llvm_config)
    if not fs.host_exists(llvm_clang):
        return comp_fail(ctx, "missing LLVM clang: " ++ llvm_clang)
    if not fs.host_exists(libclang):
        return comp_fail(ctx, "missing libclang: " ++ libclang)
    var argv: Vec[str] = Vec.new()
    argv |> push(llvm_config)
    argv |> push("--link-static")
    argv |> push("--libfiles")
    let components: [58]str = [
        "core", "support", "analysis", "passes",
        "aarch64codegen", "aarch64asmparser", "aarch64desc", "aarch64info", "aarch64utils",
        "codegen", "mc", "mcparser", "target", "targetparser", "bitwriter",
        "objcarcopts", "linker", "selectiondag", "asmprinter", "globalisel",
        "scalaropts", "instcombine", "ipo", "transformutils", "vectorize",
        "instrumentation", "cfguard", "aggressiveinstcombine",
        "irprinter", "hipstdpar", "coroutines", "sandboxir",
        "frontendopenmp", "frontenddirective", "frontendatomic", "frontendoffloading",
        "objectyaml", "cgdata", "codegentypes", "bitreader", "irreader", "asmparser",
        "profiledata", "symbolize", "debuginfobtf", "debuginfopdb", "debuginfomsf",
        "debuginfocodeview", "debuginfogsym", "debuginfodwarf", "debuginfodwarflowlevel",
        "object", "textapi", "remarks", "bitstreamreader", "binaryformat",
        "frontendhlsl", "demangle",
    ]
    for ci in 0..58:
        argv |> push(components[ci])
    let libs_text = comp_capture_stdout(ctx, "llvm-config-libfiles", argv, 120000)
    if libs_text.len() == 0:
        return comp_fail(ctx, "could not query llvm-config")
    var rsp = ""
    let libs = comp_split_whitespace(libs_text)
    for li in 0..libs.len() as i32:
        rsp = rsp ++ libs.get(li as i64) ++ "\n"
    let sdk_path = comp_host_sdk_path(ctx)
    if sdk_path.len() > 0:
        rsp = rsp ++ "-isysroot\n" ++ sdk_path ++ "\n"
    rsp = rsp ++ "-lm\n"
    rsp = rsp ++ "-lz\n"
    let zstd_archive = "/opt/homebrew/lib/libzstd.a"
    if fs.host_exists(zstd_archive):
        rsp = rsp ++ zstd_archive ++ "\n"
    else:
        rsp = rsp ++ "-lzstd\n"
    rsp = rsp ++ "-lxml2\n"
    rsp = rsp ++ "-lc++\n"
    rsp = rsp ++ libclang ++ "\n"
    rsp = rsp ++ "-Wl,-rpath," ++ comp_dirname(libclang) ++ "/\n"
    let rsp_path = comp_join(output_dir, "llvm_link.rsp")
    let cc_path = comp_join(output_dir, "llvm_cc")
    if fs.write_text(rsp_path, rsp) != 0:
        return comp_fail(ctx, "could not write: " ++ rsp_path)
    if fs.write_text(cc_path, llvm_clang ++ "\n") != 0:
        return comp_fail(ctx, "could not write: " ++ cc_path)
    if fs.write_text(output_path, "ok\n") != 0:
        return comp_fail(ctx, "could not write stamp: " ++ output_path)
    0
