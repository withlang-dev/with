module build.package

use std.build
use std.sysinfo

fn pkg_fail(ctx: &ActionCtx, message: str) -> i32:
    ctx.diagnostics().error(ctx.target_name() ++ ": " ++ message)
    1

fn pkg_join(left: str, right: str) -> str:
    if left.len() == 0:
        return right
    if right.len() == 0:
        return left
    if left.ends_with("/"):
        return left ++ right
    left ++ "/" ++ right

fn pkg_dirname(path: str) -> str:
    var last_slash = -1
    for i in 0..path.len() as i32:
        let ch = path.byte_at(i as i64)
        if ch == 47 or ch == 92:
            last_slash = i
    if last_slash < 0:
        return "."
    if last_slash == 0:
        return "/"
    path.slice(0, last_slash as i64)

fn pkg_abs(root: str, path: str) -> str:
    if pkg_is_abs(path):
        return path
    pkg_join(root, path)

fn pkg_is_abs(path: str) -> bool:
    if path.len() == 0:
        return false
    if path.byte_at(0) == 47 or path.byte_at(0) == 92:
        return true
    if os() == "Windows" and path.len() >= 3:
        let drive = path.byte_at(0)
        let colon = path.byte_at(1)
        let slash = path.byte_at(2)
        if colon == 58 and (slash == 47 or slash == 92):
            return (drive >= 65 and drive <= 90) or (drive >= 97 and drive <= 122)
    false

fn pkg_trim_line(text: str) -> str:
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

fn pkg_normalize_path(path: str) -> str:
    var out = ""
    for i in 0..path.len() as i32:
        let ch = path.byte_at(i as i64)
        if ch == 92:
            out = out ++ "/"
        else:
            out = out ++ path.slice(i as i64, (i + 1) as i64)
    out

fn pkg_str_compare(a: str, b: str) -> i32:
    let n = if a.len() < b.len(): a.len() else: b.len()
    var i = 0
    while i < n as i32:
        let ac = a.byte_at(i as i64)
        let bc = b.byte_at(i as i64)
        if ac != bc:
            return ac - bc
        i = i + 1
    if a.len() == b.len():
        return 0
    if a.len() < b.len():
        return -1
    1

fn pkg_sort_strings(items: Vec[str]) -> Vec[str]:
    var sorted: Vec[str] = Vec.new()
    for i in 0..items.len() as i32:
        let item = items.get(i as i64)
        var inserted = false
        var out: Vec[str] = Vec.new()
        for j in 0..sorted.len() as i32:
            let existing = sorted.get(j as i64)
            if not inserted and pkg_str_compare(item, existing) < 0:
                out.push(item)
                inserted = true
            out.push(existing)
        if not inserted:
            out.push(item)
        sorted = out
    sorted

fn pkg_add_unique(items: Vec[str], item: str) -> Vec[str]:
    var out = items
    for i in 0..out.len() as i32:
        if out.get(i as i64) == item:
            return out
    out.push(item)
    out

fn pkg_rel_path(root: str, path: str) -> str:
    let normalized_root = pkg_normalize_path(root)
    let normalized_path = pkg_normalize_path(path)
    let prefix = if normalized_root.ends_with("/"): normalized_root else: normalized_root ++ "/"
    if normalized_path.starts_with(prefix):
        return normalized_path.slice(prefix.len(), normalized_path.len())
    ""

fn pkg_add_parent_dirs(dirs: Vec[str], top_dir: str, rel_path: str) -> Vec[str]:
    var out = pkg_add_unique(dirs, top_dir)
    for i in 0..rel_path.len() as i32:
        if rel_path.byte_at(i as i64) == 47:
            out = pkg_add_unique(out, top_dir ++ "/" ++ rel_path.slice(0, i as i64))
    out

fn pkg_host_exe_suffix() -> str:
    if os() == "Windows":
        return ".exe"
    ""

fn pkg_current_platform() -> str:
    if os() == "Macos" and (arch() == "armv8" or arch() == "aarch64"):
        return "darwin-aarch64"
    if os() == "Linux" and arch() == "x86_64":
        return "linux-x86_64"
    if os() == "Windows" and arch() == "x86_64":
        return "windows-x86_64"
    ""

fn pkg_env_or(ctx: &ActionCtx, name: str, fallback: str) -> str:
    let value = ctx.env_input(name)
    if value.len() > 0:
        return value
    fallback

fn pkg_tool_from_env(ctx: &ActionCtx, primary: str, legacy: str, fallback: str) -> str:
    let explicit = ctx.env_input(primary)
    if explicit.len() > 0:
        return explicit
    let old = ctx.env_input(legacy)
    if old.len() > 0:
        return old
    fallback

fn pkg_llvm_prefix(ctx: &ActionCtx) -> str:
    let args = ctx.args()
    let fallback = if args.len() > 3: args.get(3) else: ""
    pkg_env_or(ctx, "LLVM_PREFIX", fallback)

fn pkg_llvm_tool(ctx: &ActionCtx, primary: str, legacy: str, name: str) -> str:
    let fallback = pkg_join(pkg_llvm_prefix(ctx), "bin/" ++ name ++ pkg_host_exe_suffix())
    pkg_tool_from_env(ctx, primary, legacy, fallback)

fn pkg_path_exists(ctx: &ActionCtx, path: str) -> bool:
    if pkg_is_abs(path):
        return ctx.fs().host_exists(path)
    ctx.fs().exists(path)

fn pkg_process_path(root: str, path: str) -> str:
    if pkg_is_abs(path):
        return path
    pkg_abs(root, path)

fn pkg_ascii_lower(text: str) -> str:
    var out = StringBuilder.with_capacity(text.len())
    for i in 0..text.len() as i32:
        let ch = text.byte_at(i as i64)
        if ch >= 65 and ch <= 90:
            out.push_byte((ch + 32) as u8)
        else:
            out.push_byte(ch as u8)
    out.to_str()

fn pkg_forbidden_dependency(text: str, platform: str) -> str:
    let lower = pkg_ascii_lower(text)
    let needles: Vec[str] = Vec.new()
    needles.push("clang")
    needles.push("llvm")
    needles.push("libz")
    needles.push("libxml2")
    needles.push("zstd")
    if platform == "linux-x86_64":
        needles.push("libstdc++")
        needles.push("libgcc_s")
        needles.push("libc++")
        needles.push("libc++abi")
    if platform == "windows-x86_64":
        needles.push("msvcp")
        needles.push("vcruntime")
        needles.push("zlib")
    for i in 0..needles.len() as i32:
        let needle = needles.get(i as i64)
        if lower.contains(needle):
            return needle
    ""

fn pkg_run_capture(ctx: &ActionCtx, label: str, argv: Vec[str], timeout_ms: i32) -> ToolProcessResult:
    let root = ctx.project_info().project_root()
    let command_dir = "out/command/" ++ ctx.target_name()
    let _mkdir = ctx.fs().mkdir_all(command_dir)
    let stdout_path = pkg_abs(root, pkg_join(command_dir, label ++ ".stdout"))
    let stderr_path = pkg_abs(root, pkg_join(command_dir, label ++ ".stderr"))
    ctx.process_runner().run_capture(argv, stdout_path, stderr_path, timeout_ms)

fn pkg_run_asset_version(ctx: &ActionCtx, asset_path: str, version: str) -> i32:
    let root = ctx.project_info().project_root()
    let args: Vec[str] = Vec.new()
    args.push(pkg_abs(root, asset_path))
    args.push("version")
    let result = pkg_run_capture(ctx, "asset-version", args, 120000)
    if result.rc != 0:
        return pkg_fail(ctx, "release binary version check failed" ++ f" (exit code {result.rc}): " ++ result.stdout ++ result.stderr)
    let actual = pkg_trim_line(result.stdout)
    if actual != "with " ++ version:
        return pkg_fail(ctx, "release binary reported '" ++ actual ++ "', expected 'with " ++ version ++ "'")
    0

fn pkg_check_dynamic_dependencies(ctx: &ActionCtx, asset_path: str, platform: str, label: str) -> i32:
    let root = ctx.project_info().project_root()
    let readobj = pkg_llvm_tool(ctx, "WITH_LLVM_READOBJ", "LLVM_READOBJ", "llvm-readobj")
    if not pkg_path_exists(ctx, readobj):
        return pkg_fail(ctx, "missing With-owned llvm-readobj: " ++ readobj)
    let args: Vec[str] = Vec.new()
    args.push(pkg_process_path(root, readobj))
    if platform == "windows-x86_64":
        args.push("--coff-imports")
    else:
        args.push("--needed-libs")
    args.push(pkg_abs(root, asset_path))
    let result = pkg_run_capture(ctx, label ++ "-deps", args, 120000)
    if result.rc != 0:
        return pkg_fail(ctx, "could not inspect release binary dependencies" ++ f" (exit code {result.rc}): " ++ result.stdout ++ result.stderr)
    let forbidden = pkg_forbidden_dependency(result.stdout ++ "\n" ++ result.stderr, platform)
    if forbidden.len() > 0:
        return pkg_fail(ctx, "release binary has forbidden dynamic compiler/support dependency matching '" ++ forbidden ++ "'\n" ++ result.stdout)
    0

fn pkg_check_static_libclang_symbol(ctx: &ActionCtx, asset_path: str, platform: str) -> i32:
    if platform == "windows-x86_64":
        return 0
    let root = ctx.project_info().project_root()
    let nm = pkg_llvm_tool(ctx, "WITH_LLVM_NM", "LLVM_NM", "llvm-nm")
    if not pkg_path_exists(ctx, nm):
        return pkg_fail(ctx, "missing With-owned llvm-nm: " ++ nm)
    let args: Vec[str] = Vec.new()
    args.push(pkg_process_path(root, nm))
    args.push("-g")
    args.push(pkg_abs(root, asset_path))
    let result = pkg_run_capture(ctx, "static-libclang-symbols", args, 120000)
    if result.rc != 0:
        return pkg_fail(ctx, "could not inspect release binary symbols" ++ f" (exit code {result.rc}): " ++ result.stdout ++ result.stderr)
    if not result.stdout.contains("clang_createIndex"):
        return pkg_fail(ctx, "release binary does not contain static libclang symbols")
    0

fn pkg_strip_release_binary(ctx: &ActionCtx, asset_path: str) -> i32:
    let root = ctx.project_info().project_root()
    let strip = pkg_llvm_tool(ctx, "WITH_LLVM_STRIP", "LLVM_STRIP", "llvm-strip")
    if not pkg_path_exists(ctx, strip):
        return pkg_fail(ctx, "missing With-owned llvm-strip: " ++ strip)
    let args: Vec[str] = Vec.new()
    args.push(pkg_process_path(root, strip))
    args.push(pkg_abs(root, asset_path))
    let result = pkg_run_capture(ctx, "strip", args, 300000)
    if result.rc != 0:
        return pkg_fail(ctx, "llvm-strip failed" ++ f" (exit code {result.rc}): " ++ result.stdout ++ result.stderr)
    0

fn pkg_write_release_checksum(ctx: &ActionCtx, asset_path: str) -> i32:
    let sha = ctx.fs().sha256_file(asset_path)
    if sha.len() == 0:
        return pkg_fail(ctx, "could not hash release asset: " ++ asset_path)
    pkg_write_text(ctx, asset_path ++ ".sha256", sha ++ "  " ++ asset_path ++ "\n")

fn pkg_write_text(ctx: &ActionCtx, path: str, text: str) -> i32:
    let fs = ctx.fs()
    let dir = pkg_dirname(path)
    if dir != "." and fs.mkdir_all(dir) != 0:
        return pkg_fail(ctx, "could not create directory: " ++ dir)
    if fs.write_text(path, text) != 0:
        return pkg_fail(ctx, "could not write: " ++ path)
    0

fn pkg_copy_file(ctx: &ActionCtx, source: str, dest: str) -> i32:
    let fs = ctx.fs()
    let dir = pkg_dirname(dest)
    if dir != "." and fs.mkdir_all(dir) != 0:
        return pkg_fail(ctx, "could not create directory: " ++ dir)
    if fs.copy_file(source, dest) != 0:
        return pkg_fail(ctx, "could not copy " ++ source ++ " to " ++ dest)
    0

fn pkg_emit_c(ctx: &ActionCtx, compiler_path: str, source: str, output: str, label: str) -> i32:
    let fs = ctx.fs()
    let root = ctx.project_info().project_root()
    let dir = pkg_dirname(output)
    if dir != "." and fs.mkdir_all(dir) != 0:
        return pkg_fail(ctx, "could not create directory: " ++ dir)
    let args: Vec[str] = Vec.new()
    args.push(pkg_abs(root, compiler_path))
    args.push("build")
    args.push(source)
    args.push("--emit-c")
    args.push("--no-prelude")
    args.push("-o")
    args.push(output)
    let command_dir = "out/command/" ++ ctx.target_name()
    if fs.mkdir_all(command_dir) != 0:
        return pkg_fail(ctx, "could not create command capture directory: " ++ command_dir)
    let stdout_path = pkg_abs(root, pkg_join(command_dir, label ++ ".stdout"))
    let stderr_path = pkg_abs(root, pkg_join(command_dir, label ++ ".stderr"))
    let result = ctx.process_runner().run_capture_cwd(args, stdout_path, stderr_path, 300000, root)
    if result.rc != 0:
        return pkg_fail(ctx, "emit-c failed for " ++ source ++ f" with exit code {result.rc}: " ++ result.stderr)
    if not fs.exists(output):
        return pkg_fail(ctx, "emit-c did not produce " ++ output)
    0

fn pkg_bootstrap_types_header() -> str:
    "#ifndef WITH_BOOTSTRAP_TYPES_H\n" ++
    "#define WITH_BOOTSTRAP_TYPES_H\n\n" ++
    "#include <stdint.h>\n" ++
    "#include <stdbool.h>\n" ++
    "#include <stddef.h>\n\n" ++
    "typedef struct {\n" ++
    "    const char *ptr;\n" ++
    "    int64_t len;\n" ++
    "} with_str;\n\n" ++
    "#define WITH_STR_LIT(s) ((with_str){(s), (int64_t)(sizeof(s) - 1)})\n" ++
    "#define with_len(v) ((v).len)\n" ++
    "#define with_is_empty(v) (((v).len == 0) ? 1 : 0)\n\n" ++
    "typedef struct {\n" ++
    "    void *ptr;\n" ++
    "    int64_t len;\n" ++
    "    int64_t cap;\n" ++
    "    int64_t elem_size;\n" ++
    "} with_vec;\n\n" ++
    "#endif\n"

fn pkg_readme(version: str) -> str:
    "# With " ++ version ++ " Bootstrap C Bundle\n\n" ++
    "This bundle is for bootstrapping With on a host that does not already have a native With compiler.\n\n" ++
    "It contains emitted C for the compiler, LLVM/libclang bridges, runtime core, panic and regex runtime, fiber stubs, compatibility runtime, and temporary Linux and Windows bootstrap platform shims.\n\n" ++
    "The bootstrap compiler is temporary. Use it only to run the normal With stage chain on the target platform:\n\n" ++
    "    WITH=/path/to/with-bootstrap with build\n" ++
    "    with build :fixpoint\n" ++
    "    with build :test\n\n" ++
    "## Linux x86_64 Compile Sketch\n\n" ++
    "Build a With-owned static LLVM SDK first:\n\n" ++
    "    HOST_TAG=linux-x86_64 tools/build-static-llvm.sh\n\n" ++
    "Then compile the C files and link with a C++ linker driver because LLVM's static libraries contain C++:\n\n" ++
    "    LLVM_PREFIX=/path/to/llvm-static-sdk\n" ++
    "    CLANG=\"$LLVM_PREFIX/bin/clang\"\n" ++
    "    CLANGXX=\"$LLVM_PREFIX/bin/clang++\"\n" ++
    "    test -x \"$CLANG\"\n" ++
    "    test -x \"$CLANGXX\"\n" ++
    "    mkdir -p obj\n\n" ++
    "    \"$CLANG\" -std=gnu11 -O2 -D_GNU_SOURCE -Iruntime -I\"$LLVM_PREFIX/include\" \\\n" ++
    "      -include runtime/wl_decls.h -c src/with_compiler.c -o obj/with_compiler.o\n\n" ++
    "    for file in src/llvm_bridge.c src/clang_bridge.c src/linux_platform.c; do\n" ++
    "      \"$CLANG\" -std=gnu11 -O2 -D_GNU_SOURCE -Iruntime -I\"$LLVM_PREFIX/include\" \\\n" ++
    "        -c \"$file\" -o \"obj/$(basename \"$file\" .c).o\"\n" ++
    "    done\n\n" ++
    "    for file in src/rt_core.c src/panic_runtime.c src/regex_runtime.c src/fiber_stubs.c src/compat_runtime.c; do\n" ++
    "      \"$CLANG\" -std=gnu11 -O2 -D_GNU_SOURCE -DWITH_RUNTIME_H -Iruntime -I\"$LLVM_PREFIX/include\" \\\n" ++
    "        -include runtime/bootstrap_types.h -c \"$file\" -o \"obj/$(basename \"$file\" .c).o\"\n" ++
    "    done\n" ++
    "    \"$CLANGXX\" obj/*.o \\\n" ++
    "      -Wl,--start-group \"$LLVM_PREFIX\"/lib/libclang*.a \"$LLVM_PREFIX\"/lib/libLLVM*.a \"$LLVM_PREFIX\"/lib/liblld*.a -Wl,--end-group \\\n" ++
    "      -lpthread -ldl -lm -lz -lzstd -lxml2 -lc \\\n" ++
    "      -o with-bootstrap\n\n" ++
    "Exact LLVM archive ordering may need adjustment by platform/linker. The release compiler is not this bootstrap binary; the release compiler is the byte-checked output of the With stage chain.\n"

fn pkg_write_sha256sums(ctx: &ActionCtx, stage_root: str) -> i32:
    let fs = ctx.fs()
    let files = pkg_sort_strings(fs.list_files(stage_root))
    var manifest = ""
    for i in 0..files.len() as i32:
        let path = files.get(i as i64)
        let rel = pkg_rel_path(stage_root, path)
        if rel.len() == 0:
            return pkg_fail(ctx, "package file is outside stage root: " ++ path)
        let sha = fs.sha256_file(path)
        if sha.len() == 0:
            return pkg_fail(ctx, "could not hash package file: " ++ path)
        manifest = manifest ++ sha ++ "  ./" ++ rel ++ "\n"
    pkg_write_text(ctx, pkg_join(stage_root, "SHA256SUMS"), manifest)

fn pkg_compile_gzip_helper(ctx: &ActionCtx, compiler_path: str, helper_bin: str) -> i32:
    let fs = ctx.fs()
    let root = ctx.project_info().project_root()
    let helper_dir = pkg_dirname(helper_bin)
    if helper_dir != "." and fs.mkdir_all(helper_dir) != 0:
        return pkg_fail(ctx, "could not create gzip helper directory: " ++ helper_dir)
    let command_dir = "out/command/" ++ ctx.target_name()
    if fs.mkdir_all(command_dir) != 0:
        return pkg_fail(ctx, "could not create command capture directory: " ++ command_dir)
    let args: Vec[str] = Vec.new()
    args.push(pkg_abs(root, compiler_path))
    args.push("build")
    args.push("build/zlib_gzip.w")
    args.push("-o")
    args.push(helper_bin)
    let result = ctx.process_runner().run_capture_cwd(args, pkg_abs(root, pkg_join(command_dir, "gzip-helper-build.stdout")), pkg_abs(root, pkg_join(command_dir, "gzip-helper-build.stderr")), 300000, root)
    if result.rc != 0:
        return pkg_fail(ctx, "could not build gzip helper" ++ f" (exit code {result.rc}): " ++ result.stdout ++ result.stderr)
    if not fs.exists(helper_bin):
        return pkg_fail(ctx, "gzip helper build did not produce " ++ helper_bin)
    0

fn pkg_run_gzip_helper(ctx: &ActionCtx, helper_bin: str, input_tar: str, output_path: str) -> i32:
    let fs = ctx.fs()
    let root = ctx.project_info().project_root()
    if fs.mkdir_all(pkg_dirname(output_path)) != 0:
        return pkg_fail(ctx, "could not create release directory")
    let command_dir = "out/command/" ++ ctx.target_name()
    if fs.mkdir_all(command_dir) != 0:
        return pkg_fail(ctx, "could not create command capture directory: " ++ command_dir)
    let args: Vec[str] = Vec.new()
    args.push(pkg_abs(root, helper_bin))
    args.push(pkg_abs(root, input_tar))
    args.push(pkg_abs(root, output_path))
    let result = ctx.process_runner().run_capture_cwd(args, pkg_abs(root, pkg_join(command_dir, "gzip-helper-run.stdout")), pkg_abs(root, pkg_join(command_dir, "gzip-helper-run.stderr")), 300000, root)
    if result.rc != 0:
        return pkg_fail(ctx, "gzip helper failed" ++ f" (exit code {result.rc}): " ++ result.stdout ++ result.stderr)
    if not fs.exists(output_path):
        return pkg_fail(ctx, "gzip helper did not produce " ++ output_path)
    0

fn pkg_write_archive(ctx: &ActionCtx, compiler_path: str, stage_root: str, top_dir: str, output_path: str) -> i32:
    let fs = ctx.fs()
    let files = pkg_sort_strings(fs.list_files(stage_root))
    var dirs: Vec[str] = Vec.new()
    for i in 0..files.len() as i32:
        let rel = pkg_rel_path(stage_root, files.get(i as i64))
        if rel.len() == 0:
            return pkg_fail(ctx, "package file is outside stage root: " ++ files.get(i as i64))
        dirs = pkg_add_parent_dirs(dirs, top_dir, rel)
    dirs = pkg_sort_strings(dirs)
    let entries: Vec[ArchiveEntry] = Vec.new()
    for i in 0..dirs.len() as i32:
        entries.push(archive_dir_entry(dirs.get(i as i64), 0o755))
    for i in 0..files.len() as i32:
        let source = files.get(i as i64)
        let rel = pkg_rel_path(stage_root, source)
        entries.push(archive_file_entry(source, top_dir ++ "/" ++ rel, 0o644))
    let tmp_tar = pkg_join("out/bootstrap-c-package", top_dir ++ ".tar")
    if fs.write_tar(tmp_tar, entries) != 0:
        return pkg_fail(ctx, "could not write intermediate tar archive")
    if not fs.exists(tmp_tar):
        return pkg_fail(ctx, "intermediate tar archive is empty")
    let helper_bin = pkg_join("out/bootstrap-c-package", "zlib_gzip" ++ pkg_host_exe_suffix())
    var rc = pkg_compile_gzip_helper(ctx, compiler_path, helper_bin)
    if rc != 0:
        return rc
    rc = pkg_run_gzip_helper(ctx, helper_bin, tmp_tar, output_path)
    if rc != 0:
        return rc
    let _remove_tmp = fs.remove_file(tmp_tar)
    0

fn pkg_version(ctx: &ActionCtx) -> str:
    let version = ctx.env_input("WITH_VERSION")
    if version.len() == 0:
        ctx.diagnostics().error(ctx.target_name() ++ ": set WITH_VERSION, for example WITH_VERSION=v0.14.8")
        return ""
    let source_version = pkg_trim_line(ctx.fs().read_text("src/version"))
    if source_version != version:
        ctx.diagnostics().error(ctx.target_name() ++ ": src/version is '" ++ source_version ++ "', expected '" ++ version ++ "'")
        ctx.diagnostics().error(ctx.target_name() ++ ": update src/version and build the release from that committed version")
        return ""
    version

pub fn run_package_bootstrap_c_action(ctx: ActionCtx) -> i32:
    let args = ctx.args()
    let output_path = ctx.output()
    if args.len() == 0 or output_path.len() == 0:
        return pkg_fail(ctx, "requires release compiler arg and output path")
    let version = pkg_version(ctx)
    if version.len() == 0:
        return 1
    let compiler_path = args.get(0)
    let fs = ctx.fs()
    if not fs.exists(compiler_path):
        return pkg_fail(ctx, "missing release compiler: " ++ compiler_path)
    let top_dir = "with-bootstrap-c-" ++ version
    let stage_root = pkg_join("out/bootstrap-c-package", top_dir)
    let _remove_stage = fs.remove_tree(stage_root)
    if fs.mkdir_all(pkg_join(stage_root, "src")) != 0 or fs.mkdir_all(pkg_join(stage_root, "runtime/sys")) != 0:
        return pkg_fail(ctx, "could not create bootstrap C package staging directories")

    var rc = pkg_copy_file(ctx, "out/bootstrap-c/src/with_compiler.c", pkg_join(stage_root, "src/with_compiler.c"))
    if rc != 0: return rc
    rc = pkg_emit_c(ctx, compiler_path, "src/compiler/LlvmBridge.w", pkg_join(stage_root, "src/llvm_bridge.c"), "llvm-bridge")
    if rc != 0: return rc
    rc = pkg_emit_c(ctx, compiler_path, "src/compiler/ClangBridge.w", pkg_join(stage_root, "src/clang_bridge.c"), "clang-bridge")
    if rc != 0: return rc
    rc = pkg_emit_c(ctx, compiler_path, "rt/rt_core.w", pkg_join(stage_root, "src/rt_core.c"), "rt-core")
    if rc != 0: return rc
    rc = pkg_emit_c(ctx, compiler_path, "rt/panic_runtime.w", pkg_join(stage_root, "src/panic_runtime.c"), "panic-runtime")
    if rc != 0: return rc
    rc = pkg_emit_c(ctx, compiler_path, "rt/regex_runtime.w", pkg_join(stage_root, "src/regex_runtime.c"), "regex-runtime")
    if rc != 0: return rc
    rc = pkg_emit_c(ctx, compiler_path, "rt/fiber_stubs.w", pkg_join(stage_root, "src/fiber_stubs.c"), "fiber-stubs")
    if rc != 0: return rc
    rc = pkg_emit_c(ctx, compiler_path, "rt/compat_runtime.w", pkg_join(stage_root, "src/compat_runtime.c"), "compat-runtime")
    if rc != 0: return rc

    rc = pkg_copy_file(ctx, "runtime/with_runtime.h", pkg_join(stage_root, "runtime/with_runtime.h"))
    if rc != 0: return rc
    rc = pkg_copy_file(ctx, "runtime/unistd.h", pkg_join(stage_root, "runtime/unistd.h"))
    if rc != 0: return rc
    rc = pkg_copy_file(ctx, "runtime/undef_stdio_macros.h", pkg_join(stage_root, "runtime/undef_stdio_macros.h"))
    if rc != 0: return rc
    rc = pkg_copy_file(ctx, "runtime/sys/resource.h", pkg_join(stage_root, "runtime/sys/resource.h"))
    if rc != 0: return rc
    rc = pkg_write_text(ctx, pkg_join(stage_root, "runtime/bootstrap_types.h"), pkg_bootstrap_types_header())
    if rc != 0: return rc
    rc = pkg_copy_file(ctx, "out/gen/wl_decls.h", pkg_join(stage_root, "runtime/wl_decls.h"))
    if rc != 0: return rc

    rc = pkg_copy_file(ctx, "scripts/bootstrap/linux_platform.c", pkg_join(stage_root, "src/linux_platform.c"))
    if rc != 0: return rc
    rc = pkg_copy_file(ctx, "scripts/bootstrap/windows_platform.c", pkg_join(stage_root, "src/windows_platform.c"))
    if rc != 0: return rc
    rc = pkg_copy_file(ctx, "scripts/bootstrap/windows_compat_runtime.c", pkg_join(stage_root, "src/windows_compat_runtime.c"))
    if rc != 0: return rc
    rc = pkg_copy_file(ctx, "scripts/bootstrap/empty_embedded_windows.s", pkg_join(stage_root, "src/empty_embedded_windows.s"))
    if rc != 0: return rc

    rc = pkg_write_text(ctx, pkg_join(stage_root, "README.bootstrap.md"), pkg_readme(version))
    if rc != 0: return rc
    rc = pkg_write_sha256sums(ctx, stage_root)
    if rc != 0: return rc
    pkg_write_archive(ctx, compiler_path, stage_root, top_dir, output_path)

pub fn run_package_platform_release_action(ctx: ActionCtx) -> i32:
    let args = ctx.args()
    if args.len() < 4:
        return pkg_fail(ctx, "requires asset name, platform tag, compiler path, and default LLVM prefix")
    let asset = args.get(0)
    let platform = args.get(1)
    let compiler_path = args.get(2)
    let current = pkg_current_platform()
    if current.len() == 0:
        return pkg_fail(ctx, "unsupported release packaging host: " ++ os() ++ "/" ++ arch())
    if current != platform:
        return pkg_fail(ctx, "target packages must be built on their native host; requested " ++ platform ++ " on " ++ current)
    let version = pkg_version(ctx)
    if version.len() == 0:
        return 1
    let fs = ctx.fs()
    if not fs.exists(compiler_path):
        return pkg_fail(ctx, "missing release compiler: " ++ compiler_path)
    let asset_path = pkg_join("out/release", asset)
    if fs.mkdir_all("out/release") != 0:
        return pkg_fail(ctx, "could not create release directory")
    if fs.copy_file(compiler_path, asset_path) != 0:
        return pkg_fail(ctx, "could not copy release compiler to " ++ asset_path)
    if platform != "windows-x86_64" and fs.chmod(asset_path, 0o755) != 0:
        return pkg_fail(ctx, "could not chmod release asset: " ++ asset_path)
    var rc = pkg_run_asset_version(ctx, asset_path, version)
    if rc != 0: return rc
    rc = pkg_check_dynamic_dependencies(ctx, asset_path, platform, "before-strip")
    if rc != 0: return rc
    rc = pkg_check_static_libclang_symbol(ctx, asset_path, platform)
    if rc != 0: return rc
    rc = pkg_strip_release_binary(ctx, asset_path)
    if rc != 0: return rc
    rc = pkg_check_dynamic_dependencies(ctx, asset_path, platform, "after-strip")
    if rc != 0: return rc
    rc = pkg_write_release_checksum(ctx, asset_path)
    if rc != 0: return rc
    let output = ctx.output()
    if output.len() > 0:
        return pkg_write_text(ctx, output, "ok\n")
    0
