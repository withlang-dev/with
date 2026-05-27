module build.compiler

use std.build
use std.process
use std.sysinfo

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

fn comp_path_basename(path: str) -> str:
    var last_slash: i64 = -1
    for i in 0..path.len() as i32:
        if path.byte_at(i as i64) == 47:
            last_slash = i as i64
    if last_slash >= 0:
        return path.slice(last_slash + 1, path.len())
    path

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

fn comp_llvm_clang_tool() -> str:
    comp_tool_from_env("WITH_LLVM_CC", "LLVM_CC", comp_llvm_prefix() ++ "/bin/clang")

fn comp_llvm_lld_tool() -> str:
    let fallback = if os() == "Linux": comp_llvm_prefix() ++ "/bin/ld.lld" else: comp_llvm_prefix() ++ "/bin/ld64.lld"
    comp_tool_from_env("WITH_LLVM_LD", "LLVM_LD", fallback)

fn comp_libclang_path() -> str:
    let explicit = env("WITH_LIBCLANG")
    if explicit.len() > 0:
        return explicit
    let legacy = env("LIBCLANG_FILE")
    if legacy.len() > 0:
        return legacy
    comp_llvm_prefix() ++ "/lib/libclang.dylib"

fn comp_select_libclang_path(fs: ToolFs) -> str:
    let explicit = env("WITH_LIBCLANG")
    if explicit.len() > 0:
        return explicit
    let legacy = env("LIBCLANG_FILE")
    if legacy.len() > 0:
        return legacy
    let static_libclang = comp_llvm_prefix() ++ "/lib/libclang.a"
    if fs.host_exists(static_libclang):
        return static_libclang
    ""

fn comp_link_path_is_dynamic(path: str) -> bool:
    not path.ends_with(".a")

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
    let llvm_clang = comp_llvm_clang_tool()
    let llvm_ld = comp_llvm_lld_tool()
    let libclang = comp_select_libclang_path(fs)
    if not fs.host_exists(llvm_ld):
        return comp_fail(ctx, "missing LLVM linker: " ++ llvm_ld)
    if libclang.len() == 0:
        return comp_fail(ctx, "missing static libclang archive: " ++ comp_llvm_prefix() ++ "/lib/libclang.a")
    if not libclang.ends_with(".a"):
        return comp_fail(ctx, "libclang must be linked statically; expected libclang.a, got: " ++ libclang)
    if not fs.host_exists(libclang):
        return comp_fail(ctx, "missing static libclang archive: " ++ libclang)
    let llvm_lib_dir = comp_llvm_prefix() ++ "/lib"
    let lib_files = fs.host_list_files(llvm_lib_dir)
    if lib_files.len() == 0:
        return comp_fail(ctx, "could not list: " ++ llvm_lib_dir)
    var clang_archives: Vec[str] = Vec.new()
    var llvm_archives: Vec[str] = Vec.new()
    for i in 0..lib_files.len() as i32:
        let path = lib_files.get(i as i64)
        let name = comp_path_basename(path)
        if name.ends_with(".a"):
            if name.starts_with("libclang") and path != libclang:
                clang_archives.push(path)
            else:
                if name.starts_with("libLLVM"):
                    llvm_archives.push(path)
    var rsp = ""
    var ld_rsp = ""
    rsp = rsp ++ libclang ++ "\n"
    ld_rsp = ld_rsp ++ libclang ++ "\n"
    let sorted_clang_archives = comp_sort_strings(clang_archives)
    for i in 0..sorted_clang_archives.len() as i32:
        let path = sorted_clang_archives.get(i as i64)
        rsp = rsp ++ path ++ "\n"
        ld_rsp = ld_rsp ++ path ++ "\n"
    let sorted_llvm_archives = comp_sort_strings(llvm_archives)
    for i in 0..sorted_llvm_archives.len() as i32:
        let path = sorted_llvm_archives.get(i as i64)
        rsp = rsp ++ path ++ "\n"
        ld_rsp = ld_rsp ++ path ++ "\n"
    if os() == "Macos":
        let sdk_path = comp_host_sdk_path(ctx)
        if sdk_path.len() > 0:
            rsp = rsp ++ "-isysroot\n" ++ sdk_path ++ "\n"
            ld_rsp = ld_rsp ++ "-syslibroot\n" ++ sdk_path ++ "\n"
        rsp = rsp ++ "-lm\n"
        rsp = rsp ++ "-lc++\n"
        ld_rsp = ld_rsp ++ "-lm\n"
        ld_rsp = ld_rsp ++ "-lc++\n"
    else if os() == "Linux":
        rsp = rsp ++ "-lpthread\n"
        rsp = rsp ++ "-ldl\n"
        rsp = rsp ++ "-lm\n"
        rsp = rsp ++ "-static-libstdc++\n"
        rsp = rsp ++ "-static-libgcc\n"
        rsp = rsp ++ "-lz\n"
        rsp = rsp ++ "-lzstd\n"
        rsp = rsp ++ "-lxml2\n"
        ld_rsp = ld_rsp ++ "-Bstatic\n"
        ld_rsp = ld_rsp ++ "-lstdc++\n"
        ld_rsp = ld_rsp ++ "-lgcc\n"
        ld_rsp = ld_rsp ++ "-lgcc_eh\n"
        ld_rsp = ld_rsp ++ "-Bdynamic\n"
        ld_rsp = ld_rsp ++ "-lpthread\n"
        ld_rsp = ld_rsp ++ "-ldl\n"
        ld_rsp = ld_rsp ++ "-lm\n"
        ld_rsp = ld_rsp ++ "-lz\n"
        ld_rsp = ld_rsp ++ "-lzstd\n"
        ld_rsp = ld_rsp ++ "-lxml2\n"
    else:
        return comp_fail(ctx, "unsupported host for LLVM link metadata: " ++ os() ++ "/" ++ arch())
    if comp_link_path_is_dynamic(libclang):
        rsp = rsp ++ "-Wl,-rpath," ++ comp_dirname(libclang) ++ "/\n"
    if comp_link_path_is_dynamic(libclang):
        ld_rsp = ld_rsp ++ "-rpath\n" ++ comp_dirname(libclang) ++ "/\n"
    let rsp_path = comp_join(output_dir, "llvm_link.rsp")
    let cc_path = comp_join(output_dir, "llvm_cc")
    let ld_rsp_path = comp_join(output_dir, "llvm_ld.rsp")
    let ld_path = comp_join(output_dir, "llvm_ld")
    if fs.write_text(rsp_path, rsp) != 0:
        return comp_fail(ctx, "could not write: " ++ rsp_path)
    if fs.write_text(cc_path, llvm_clang ++ "\n") != 0:
        return comp_fail(ctx, "could not write: " ++ cc_path)
    if fs.write_text(ld_rsp_path, ld_rsp) != 0:
        return comp_fail(ctx, "could not write: " ++ ld_rsp_path)
    if fs.write_text(ld_path, llvm_ld ++ "\n") != 0:
        return comp_fail(ctx, "could not write: " ++ ld_path)
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
    let fs = ctx.fs()
    let manifest = fs.read_text("out/.build-state/blessed-manifest")
    if manifest.len() == 0:
        ctx.diagnostics().error("no blessed manifest found; run `with build :fixpoint` first or pass --force")
        return 1
    let changed = comp_check_manifest(fs, manifest)
    if changed.len() > 0:
        ctx.diagnostics().error("source files changed since last fixpoint:\n" ++ changed ++ "run `with build :fixpoint` to re-bless, or pass --force")
        return 1
    fs.write_text("out/command/" ++ ctx.target_name() ++ "/ok", "ok\n")
    0

pub fn run_bless_manifest_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    fs.mkdir_all("out/.build-state")
    let manifest = comp_build_source_manifest(fs)
    if manifest.len() == 0:
        return comp_fail(ctx, "could not build source manifest")
    if fs.write_text("out/.build-state/blessed-manifest", manifest) != 0:
        return comp_fail(ctx, "could not write blessed-manifest")
    0

fn comp_build_source_manifest(fs: ToolFs) -> str:
    let dirs: Vec[str] = Vec.new()
    dirs.push("src")
    dirs.push("rt")
    dirs.push("lib/std")
    dirs.push("build")
    let all_files: Vec[str] = Vec.new()
    for di in 0..dirs.len() as i32:
        let dir = dirs.get(di as i64)
        let listing = fs.list_files(dir)
        for fi in 0..listing.len() as i32:
            let path = listing.get(fi as i64)
            if path.ends_with(".w"):
                all_files.push(path)
    all_files.push("build.w")
    let sorted = comp_sort_strings(all_files)
    var manifest = ""
    for i in 0..sorted.len() as i32:
        let path = sorted.get(i as i64)
        let contents = fs.read_text(path)
        let hash = comp_fnv1a(contents)
        manifest = manifest ++ path ++ ":" ++ f"{hash}" ++ "\n"
    manifest

fn comp_check_manifest(fs: ToolFs, manifest: str) -> str:
    var changed = ""
    var line_start: i64 = 0
    for i in 0..manifest.len() as i32:
        if manifest.byte_at(i as i64) == 10:
            let line = manifest.slice(line_start, i as i64)
            if line.len() > 0:
                let sep = comp_last_colon_pos(line)
                if sep > 0:
                    let path = line.slice(0, sep)
                    let expected_str = line.slice(sep + 1, line.len())
                    let contents = fs.read_text(path)
                    let actual = comp_fnv1a(contents)
                    if f"{actual}" != expected_str:
                        changed = changed ++ "  " ++ path ++ "\n"
            line_start = i as i64 + 1
    changed

fn comp_fnv1a(s: str) -> i64:
    var h: i64 = -3750763034362895579
    for i in 0..s.len() as i32:
        h = h ^ (s.byte_at(i as i64) as i64)
        h = h * 1099511628211
    h

fn comp_last_colon_pos(line: str) -> i64:
    var pos: i64 = -1
    for i in 0..line.len() as i32:
        if line.byte_at(i as i64) == 58:
            pos = i as i64
    pos

fn comp_str_compare(a: str, b: str) -> i32:
    let min_len = if a.len() < b.len(): a.len() else: b.len()
    for i in 0..min_len as i32:
        let ac = a.byte_at(i as i64)
        let bc = b.byte_at(i as i64)
        if ac != bc:
            return ac - bc
    if a.len() == b.len():
        return 0
    if a.len() < b.len():
        return -1
    1

fn comp_sort_strings(items: Vec[str]) -> Vec[str]:
    var sorted: Vec[str] = Vec.new()
    for i in 0..items.len() as i32:
        let item = items.get(i as i64)
        var inserted = false
        var out: Vec[str] = Vec.new()
        for j in 0..sorted.len() as i32:
            let existing = sorted.get(j as i64)
            if not inserted and comp_str_compare(item, existing) < 0:
                out.push(item)
                inserted = true
            out.push(existing)
        if not inserted:
            out.push(item)
        sorted = out
    sorted
