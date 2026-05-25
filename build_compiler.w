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
    let fs = ctx.fs()
    let clt = "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk"
    if fs.host_exists(clt):
        return clt
    let xcode = "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk"
    if fs.host_exists(xcode):
        return xcode
    ""

fn comp_arg_value(args: Vec[str], prefix: str) -> str:
    for i in 0..args.len() as i32:
        let arg = args.get(i as i64)
        if arg.starts_with(prefix):
            return arg.slice(prefix.len(), arg.len())
    ""

fn comp_arg_allowed_for_compiler(arg: str) -> bool:
    not arg.starts_with("compiler=")

fn comp_resolve_seed_compiler(ctx: ActionCtx) -> str:
    let explicit = env("WITH")
    if explicit.len() > 0:
        return explicit
    let fs = ctx.fs()
    if fs.exists("out/bin/with"):
        return "out/bin/with"
    let path_env = env("PATH")
    if path_env.len() > 0:
        var start = 0
        for i in 0..path_env.len() as i32 + 1:
            let at_end = i == path_env.len() as i32
            let is_sep = not at_end and path_env.byte_at(i as i64) == 58
            if is_sep or at_end:
                if i > start:
                    let dir = path_env.slice(start as i64, i as i64)
                    let candidate = dir ++ "/with"
                    if fs.host_exists(candidate):
                        return candidate
                start = i + 1
    if fs.exists("src/main"):
        return "src/main"
    "with"

fn comp_compiler_path(ctx: ActionCtx, compiler: str) -> str:
    if compiler == "seed":
        return comp_resolve_seed_compiler(ctx)
    compiler

fn comp_path_exists(ctx: ActionCtx, path: str) -> bool:
    if path == "with":
        return true
    if path.len() > 0 and path.byte_at(0) == 47:
        return ctx.fs().host_exists(path)
    ctx.fs().exists(path)

fn comp_path_for_process(root: str, path: str) -> str:
    if path == "with":
        return path
    comp_abs(root, path)

fn comp_run_compiler_capture(ctx: ActionCtx, label: str, argv: Vec[str], stdout_path: str, stderr_path: str, timeout_ms: i32) -> i32:
    let root = ctx.project_info().project_root()
    var process_env = process_env()
    process_env = process_env.set("WITH_OUT_DIR", comp_abs(root, "out"))
    let result = ctx.process_runner().run_capture_with_env(argv, comp_abs(root, stdout_path), comp_abs(root, stderr_path), timeout_ms, process_env)
    if result.rc == 124:
        return comp_fail(ctx, "step '" ++ label ++ "' timed out; stdout=" ++ stdout_path ++ " stderr=" ++ stderr_path)
    if result.rc != 0:
        if result.stderr.len() > 0:
            ctx.diagnostics().error(result.stderr)
        return comp_fail(ctx, "step '" ++ label ++ f"' failed with exit code {result.rc}; stdout=" ++ stdout_path ++ " stderr=" ++ stderr_path)
    0

fn comp_compile_args(ctx: ActionCtx, command: str, compiler_path: str, source_path: str) -> Vec[str]:
    let root = ctx.project_info().project_root()
    let args = ctx.args()
    var argv: Vec[str] = Vec.new()
    argv |> push(comp_path_for_process(root, compiler_path))
    argv |> push(command)
    argv |> push(comp_abs(root, source_path))
    for ai in 0..args.len() as i32:
        let arg = args.get(ai as i64)
        if comp_arg_allowed_for_compiler(arg):
            argv |> push(arg)
    argv

fn comp_remove_file_if_exists(fs: ToolFs, path: str) -> i32:
    if not fs.exists(path):
        return 0
    fs.remove_file(path)

fn comp_remove_tree_if_exists(fs: ToolFs, path: str) -> i32:
    if not fs.exists(path):
        return 0
    fs.remove_tree(path)

fn comp_resolve_compiler_version(ctx: ActionCtx) -> str:
    let fs = ctx.fs()
    let root = ctx.project_info().project_root()
    let base = comp_first_trimmed_line(fs.read_text("src/version"))
    if base.len() == 0:
        return ""
    let override_version = env("WITH_VERSION")
    if override_version.len() > 0:
        return override_version
    let short_hash = comp_read_git_short_hash(fs, root)
    if short_hash.len() > 0:
        return base ++ "-g" ++ short_hash
    base

fn comp_read_git_short_hash(fs: ToolFs, root: str) -> str:
    let head_raw = fs.read_text(".git/HEAD")
    let head = comp_first_trimmed_line(head_raw)
    if head.len() == 0:
        return ""
    if head.len() > 5 and head.slice(0, 5) == "ref: ":
        let ref_path = head.slice(5, head.len())
        let loose = comp_first_trimmed_line(fs.read_text(".git/" ++ ref_path))
        if loose.len() >= 9:
            return loose.slice(0, 9)
        return comp_find_packed_ref(fs, root, ref_path)
    if head.len() >= 9:
        return head.slice(0, 9)
    ""

fn comp_find_packed_ref(fs: ToolFs, root: str, ref_path: str) -> str:
    let packed = fs.read_text(".git/packed-refs")
    if packed.len() == 0:
        return ""
    var line_start: i64 = 0
    for i in 0..packed.len() as i32:
        if packed.byte_at(i as i64) == 10:
            let line = packed.slice(line_start, i as i64)
            if line.len() > 41 and line.byte_at(0) != 35:
                let ref_in_line = line.slice(41, line.len())
                if ref_in_line == ref_path:
                    return line.slice(0, 9)
            line_start = i as i64 + 1
    if line_start < packed.len():
        let line = packed.slice(line_start, packed.len())
        if line.len() > 41 and line.byte_at(0) != 35:
            let ref_in_line = line.slice(41, line.len())
            if ref_in_line == ref_path:
                return line.slice(0, 9)
    ""

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

pub fn run_with_compiler_build_action(ctx: ActionCtx) -> i32:
    let inputs = ctx.inputs()
    let output_path = ctx.output()
    if inputs.len() == 0:
        return comp_fail(ctx, "requires a source input")
    if output_path.len() == 0:
        return comp_fail(ctx, "requires an output path")
    let compiler_arg = comp_arg_value(ctx.args(), "compiler=")
    if compiler_arg.len() == 0:
        return comp_fail(ctx, "requires compiler= argument")
    let source_path = inputs.get(0)
    let compiler_path = comp_compiler_path(ctx, compiler_arg)
    let fs = ctx.fs()
    if not fs.exists(source_path):
        return comp_fail(ctx, "missing source: " ++ source_path)
    if not comp_path_exists(ctx, compiler_path):
        return comp_fail(ctx, "missing compiler: " ++ compiler_path)
    let output_dir = comp_dirname(output_path)
    if fs.mkdir_all(output_dir) != 0:
        return comp_fail(ctx, "could not create output directory: " ++ output_dir)
    let tmp_output = output_path ++ ".tmp"
    let _remove_tmp = comp_remove_file_if_exists(fs, tmp_output)
    let _remove_tmp_dsym = comp_remove_tree_if_exists(fs, tmp_output ++ ".dSYM")
    var argv = comp_compile_args(ctx, "build", compiler_path, source_path)
    argv |> push("-o")
    argv |> push(comp_abs(ctx.project_info().project_root(), tmp_output))
    let capture_dir = comp_join("out/command", ctx.target_name())
    if fs.mkdir_all(capture_dir) != 0:
        return comp_fail(ctx, "could not create capture directory: " ++ capture_dir)
    let stdout_path = comp_join(capture_dir, "stdout.txt")
    let stderr_path = comp_join(capture_dir, "stderr.txt")
    let rc = comp_run_compiler_capture(ctx, "build", argv, stdout_path, stderr_path, 600000)
    if rc != 0:
        return rc
    if not fs.exists(tmp_output):
        return comp_fail(ctx, "did not produce output: " ++ tmp_output)
    let _remove_old = comp_remove_file_if_exists(fs, output_path)
    let _remove_old_dsym = comp_remove_tree_if_exists(fs, output_path ++ ".dSYM")
    if fs.rename(tmp_output, output_path) != 0:
        return comp_fail(ctx, "could not move output to: " ++ output_path)
    if fs.exists(tmp_output ++ ".dSYM"):
        let _move_dsym = fs.rename(tmp_output ++ ".dSYM", output_path ++ ".dSYM")
    if not output_path.contains(".o"):
        print("[" ++ ctx.target_name() ++ "] wrote " ++ output_path)
    let _remove_stdout = fs.remove_file(stdout_path)
    let _remove_stderr = fs.remove_file(stderr_path)
    0

pub fn run_with_compiler_ir_action(ctx: ActionCtx) -> i32:
    let inputs = ctx.inputs()
    let output_path = ctx.output()
    if inputs.len() == 0:
        return comp_fail(ctx, "requires a source input")
    if output_path.len() == 0:
        return comp_fail(ctx, "requires an output path")
    let compiler_arg = comp_arg_value(ctx.args(), "compiler=")
    if compiler_arg.len() == 0:
        return comp_fail(ctx, "requires compiler= argument")
    let source_path = inputs.get(0)
    let compiler_path = comp_compiler_path(ctx, compiler_arg)
    let fs = ctx.fs()
    if not fs.exists(source_path):
        return comp_fail(ctx, "missing source: " ++ source_path)
    if not comp_path_exists(ctx, compiler_path):
        return comp_fail(ctx, "missing compiler: " ++ compiler_path)
    let output_dir = comp_dirname(output_path)
    if fs.mkdir_all(output_dir) != 0:
        return comp_fail(ctx, "could not create output directory: " ++ output_dir)
    let tmp_output = output_path ++ ".tmp"
    let stderr_path = output_path ++ ".stderr"
    let _remove_tmp = comp_remove_file_if_exists(fs, tmp_output)
    let _remove_stderr = comp_remove_file_if_exists(fs, stderr_path)
    let argv = comp_compile_args(ctx, "ir", compiler_path, source_path)
    let rc = comp_run_compiler_capture(ctx, "ir", argv, tmp_output, stderr_path, 600000)
    if rc != 0:
        return rc
    if not fs.exists(tmp_output):
        return comp_fail(ctx, "did not produce output: " ++ tmp_output)
    let _remove_old = comp_remove_file_if_exists(fs, output_path)
    if fs.rename(tmp_output, output_path) != 0:
        return comp_fail(ctx, "could not move output to: " ++ output_path)
    let _remove_stderr_done = comp_remove_file_if_exists(fs, stderr_path)
    0

pub fn run_check_committed_state_action(ctx: ActionCtx) -> i32:
    let args = ctx.args()
    for i in 0..args.len() as i32:
        if args.get(i as i64) == "--force":
            return 0
    let proc = ctx.process_runner()
    let fs = ctx.fs()
    let stdout_path = "out/command/" ++ ctx.target_name() ++ "/stdout"
    let stderr_path = "out/command/" ++ ctx.target_name() ++ "/stderr"
    fs.mkdir_all("out/command/" ++ ctx.target_name())
    let git_args: Vec[str] = Vec.new()
    git_args.push("git")
    git_args.push("status")
    git_args.push("--porcelain")
    let result = proc.run_capture(git_args, stdout_path, stderr_path, 30000)
    if result.rc != 0:
        return comp_fail(ctx, "git status failed (rc=" ++ f"{result.rc}" ++ ")")
    if result.stdout.len() > 0:
        ctx.diagnostics().error(ctx.target_name() ++ ": uncommitted changes detected; commit before installing or pass --force arg")
        return 1
    fs.write_text("out/command/" ++ ctx.target_name() ++ "/ok", "ok\n")
    0
