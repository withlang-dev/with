module build.sdk

use std.build
use std.sysinfo
use build.compiler

const SDK_NINJA_VERSION: str = "1.13.1"
const SDK_NINJA_SHA256: str = "f0055ad0369bf2e372955ba55128d000cfcc21777057806015b45e4accbebf23"
const SDK_CMAKE_VERSION: str = "4.2.3"
const SDK_CMAKE_SHA256: str = "7efaccde8c5a6b2968bad6ce0fe60e19b6e10701a12fce948c2bf79bac8a11e9"
const SDK_LLVM_TAG_TAR_GZ_SHA256: str = "ba534c6835a5b9c2162c806e269799fe41fca952a3c25baff1afcff23841ec2b"

fn sdk_fail(ctx: &ActionCtx, message: str) -> i32:
    ctx.diagnostics().error(ctx.target_name() ++ ": " ++ message)
    1

fn sdk_join(left: str, right: str) -> str:
    if left.len() == 0:
        return right
    if right.len() == 0:
        return left
    if left.ends_with("/") or left.ends_with("\\"):
        return left ++ right
    left ++ "/" ++ right

fn sdk_dirname(path: str) -> str:
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

fn sdk_is_abs(path: str) -> bool:
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

fn sdk_abs(root: str, path: str) -> str:
    if sdk_is_abs(path):
        return path
    sdk_join(root, path)

fn sdk_normalize(path: str) -> str:
    var out = StringBuilder.with_capacity(path.len())
    for i in 0..path.len() as i32:
        let ch = path.byte_at(i as i64)
        if ch == 92:
            out.push_byte(47 as u8)
        else:
            out.push_byte(ch as u8)
    out.to_str()

fn sdk_basename(path: str) -> str:
    var last_slash: i64 = -1
    for i in 0..path.len() as i32:
        let ch = path.byte_at(i as i64)
        if ch == 47 or ch == 92:
            last_slash = i as i64
    if last_slash >= 0:
        return path.slice(last_slash + 1, path.len())
    path

fn sdk_rel_path(root: str, path: str) -> str:
    let nr = sdk_normalize(root)
    let np = sdk_normalize(path)
    let prefix = if nr.ends_with("/"): nr else: nr ++ "/"
    if np.starts_with(prefix):
        return np.slice(prefix.len(), np.len())
    ""

fn sdk_has_slash(text: str) -> bool:
    text.find("/") >= 0 or text.find("\\") >= 0

fn sdk_exe_suffix() -> str:
    if os() == "Windows":
        return ".exe"
    ""

fn sdk_exe_name(name: str) -> str:
    if os() == "Windows" and not name.ends_with(".exe"):
        return name ++ ".exe"
    name

pub fn sdk_current_platform() -> str:
    if os() == "Macos" and (arch() == "armv8" or arch() == "aarch64"):
        return "darwin-aarch64"
    if os() == "Linux" and arch() == "x86_64":
        return "linux-x86_64"
    if os() == "Windows" and arch() == "x86_64":
        return "windows-x86_64"
    ""

pub fn sdk_host_tag_for_platform(platform: str) -> str:
    if platform == "darwin-aarch64":
        return "darwin-arm64"
    if platform == "linux-x86_64":
        return "linux-x86_64"
    if platform == "windows-x86_64":
        return "windows-x86_64-msvc"
    "unsupported"

pub fn sdk_default_prefix_for_platform(platform: str) -> str:
    ".deps/llvm-" ++ compiler_llvm_version() ++ "-" ++ sdk_host_tag_for_platform(platform)

pub fn sdk_default_build_cache_for_platform(platform: str) -> str:
    ".deps/build/llvm-" ++ compiler_llvm_version() ++ "-" ++ sdk_host_tag_for_platform(platform) ++ "/CMakeCache.txt"

pub fn sdk_asset_for_platform(platform: str) -> str:
    "with-llvm-sdk-" ++ compiler_llvm_version() ++ "-" ++ platform ++ ".tar.gz"

pub fn sdk_output_prefix_for_platform(platform: str) -> str:
    "out/sdk/" ++ sdk_host_tag_for_platform(platform) ++ "/install/llvm-" ++ compiler_llvm_version() ++ "-" ++ sdk_host_tag_for_platform(platform)

pub fn sdk_output_build_root_for_platform(platform: str) -> str:
    "out/sdk/" ++ sdk_host_tag_for_platform(platform) ++ "/build"

pub fn sdk_output_llvm_cache_for_platform(platform: str) -> str:
    sdk_output_build_root_for_platform(platform) ++ "/llvm-" ++ compiler_llvm_version() ++ "-" ++ sdk_host_tag_for_platform(platform) ++ "/CMakeCache.txt"

pub fn sdk_source_root() -> str:
    ".deps/src"

pub fn sdk_ninja_archive() -> str:
    sdk_source_root() ++ "/ninja-" ++ SDK_NINJA_VERSION ++ ".tar.gz"

pub fn sdk_ninja_source_dir() -> str:
    sdk_source_root() ++ "/ninja-" ++ SDK_NINJA_VERSION

pub fn sdk_ninja_source_marker() -> str:
    sdk_ninja_source_dir() ++ "/.with-source-ready"

pub fn sdk_cmake_archive() -> str:
    sdk_source_root() ++ "/cmake-" ++ SDK_CMAKE_VERSION ++ ".tar.gz"

pub fn sdk_cmake_source_dir() -> str:
    sdk_source_root() ++ "/cmake-" ++ SDK_CMAKE_VERSION

pub fn sdk_cmake_source_marker() -> str:
    sdk_cmake_source_dir() ++ "/.with-source-ready"

pub fn sdk_llvm_archive() -> str:
    sdk_source_root() ++ "/llvm-project-llvmorg-" ++ compiler_llvm_version() ++ ".tar.gz"

pub fn sdk_llvm_source_dir() -> str:
    sdk_source_root() ++ "/llvm-project-llvmorg-" ++ compiler_llvm_version()

pub fn sdk_llvm_source_marker() -> str:
    sdk_llvm_source_dir() ++ "/.with-source-ready"

pub fn sdk_ninja_source_url() -> str:
    "https://github.com/ninja-build/ninja/archive/refs/tags/v" ++ SDK_NINJA_VERSION ++ ".tar.gz"

pub fn sdk_ninja_source_sha256() -> str:
    SDK_NINJA_SHA256

pub fn sdk_cmake_source_url() -> str:
    "https://github.com/Kitware/CMake/releases/download/v" ++ SDK_CMAKE_VERSION ++ "/cmake-" ++ SDK_CMAKE_VERSION ++ ".tar.gz"

pub fn sdk_cmake_source_sha256() -> str:
    SDK_CMAKE_SHA256

pub fn sdk_llvm_source_url() -> str:
    "https://github.com/llvm/llvm-project/archive/refs/tags/llvmorg-" ++ compiler_llvm_version() ++ ".tar.gz"

pub fn sdk_llvm_source_sha256() -> str:
    SDK_LLVM_TAG_TAR_GZ_SHA256

fn sdk_str_compare(a: str, b: str) -> i32:
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

fn sdk_sort_strings(items: Vec[str]) -> Vec[str]:
    var sorted: Vec[str] = Vec.new()
    for i in 0..items.len() as i32:
        let item = items.get(i as i64)
        var inserted = false
        var out: Vec[str] = Vec.new()
        for j in 0..sorted.len() as i32:
            let existing = sorted.get(j as i64)
            if not inserted and sdk_str_compare(item, existing) < 0:
                out.push(item)
                inserted = true
            out.push(existing)
        if not inserted:
            out.push(item)
        sorted = out
    sorted

fn sdk_add_unique(items: Vec[str], item: str) -> Vec[str]:
    var out = items
    for i in 0..out.len() as i32:
        if out.get(i as i64) == item:
            return out
    out.push(item)
    out

fn sdk_add_parent_dirs(dirs: Vec[str], top_dir: str, rel_path: str) -> Vec[str]:
    var out = sdk_add_unique(dirs, top_dir)
    for i in 0..rel_path.len() as i32:
        if rel_path.byte_at(i as i64) == 47:
            out = sdk_add_unique(out, top_dir ++ "/" ++ rel_path.slice(0, i as i64))
    out

fn sdk_file_exists(fs: &ToolFs, path: str) -> bool:
    fs.exists(path)

fn sdk_required_tool(prefix: str, name: str) -> str:
    sdk_join(prefix, "bin/" ++ sdk_exe_name(name))

fn sdk_tool(prefix: str, name: str) -> str:
    sdk_join(prefix, "bin/" ++ sdk_exe_name(name))

fn sdk_check_file(ctx: &ActionCtx, path: str, label: str) -> i32:
    let fs = ctx.fs()
    if not sdk_file_exists(fs, path):
        return sdk_fail(ctx, "missing " ++ label ++ ": " ++ path)
    0

fn sdk_cache_line(cache: str, key: str) -> str:
    let lines = sdk_split_lines(cache)
    for i in 0..lines.len() as i32:
        let line = lines.get(i as i64)
        if line.starts_with(key):
            return line
    ""

fn sdk_split_lines(text: str) -> Vec[str]:
    let out: Vec[str] = Vec.new()
    var start = 0
    for i in 0..text.len() as i32:
        if text.byte_at(i as i64) == 10:
            out.push(text.slice(start as i64, i as i64))
            start = i + 1
    if start <= text.len() as i32:
        out.push(text.slice(start as i64, text.len()))
    out

fn sdk_validate_cache(ctx: &ActionCtx, platform: str, cache_path: str) -> i32:
    let fs = ctx.fs()
    if not fs.exists(cache_path):
        return sdk_fail(ctx, "missing SDK build cache: " ++ cache_path)
    let cache = fs.read_text(cache_path)
    let cc = sdk_cache_line(cache, "CMAKE_C_COMPILER:")
    let cxx = sdk_cache_line(cache, "CMAKE_CXX_COMPILER:")
    if platform == "windows-x86_64":
        if not cc.contains("clang-cl") or not cxx.contains("clang-cl"):
            return sdk_fail(ctx, "refusing to package SDK not built with clang-cl; CMAKE_C_COMPILER=" ++ cc ++ " CMAKE_CXX_COMPILER=" ++ cxx)
        let masm = sdk_cache_line(cache, "CMAKE_ASM_MASM_COMPILER:")
        if not masm.contains("llvm-ml64"):
            return sdk_fail(ctx, "refusing to package SDK not built with llvm-ml64; CMAKE_ASM_MASM_COMPILER=" ++ masm)
        return 0
    if not cc.contains("clang") or cc.contains("/usr/bin/cc") or cc.contains("/usr/bin/gcc"):
        return sdk_fail(ctx, "refusing to package SDK not built with clang; CMAKE_C_COMPILER=" ++ cc)
    if not cxx.contains("clang++") or cxx.contains("/usr/bin/c++") or cxx.contains("/usr/bin/g++"):
        return sdk_fail(ctx, "refusing to package SDK not built with clang++; CMAKE_CXX_COMPILER=" ++ cxx)
    0

fn sdk_validate_package_prefix(ctx: &ActionCtx, platform: str, prefix: str, build_cache: str) -> i32:
    if sdk_is_abs(prefix) or sdk_is_abs(build_cache):
        return sdk_fail(ctx, "SDK package inputs must be project-relative graph paths, got prefix=" ++ prefix ++ " cache=" ++ build_cache)
    let current = sdk_current_platform()
    if current.len() == 0:
        return sdk_fail(ctx, "unsupported SDK packaging host: " ++ os() ++ "/" ++ arch())
    if current != platform:
        return sdk_fail(ctx, "SDK packages must be built on their native host; requested " ++ platform ++ " on " ++ current)
    var rc = sdk_validate_cache(ctx, platform, build_cache)
    if rc != 0:
        return rc
    if platform == "windows-x86_64":
        rc = sdk_check_file(ctx, sdk_join(prefix, "lib/libclang.lib"), "static libclang archive")
        if rc != 0: return rc
        let tools: Vec[str] = Vec.new()
        tools.push("clang")
        tools.push("clang++")
        tools.push("clang-cl")
        tools.push("cmake")
        tools.push("ninja")
        tools.push("lld-link")
        tools.push("llvm-lib")
        tools.push("llvm-ml")
        tools.push("llvm-ml64")
        tools.push("llvm-nm")
        tools.push("llvm-readobj")
        tools.push("llvm-strip")
        for i in 0..tools.len() as i32:
            rc = sdk_check_file(ctx, sdk_required_tool(prefix, tools.get(i as i64)), tools.get(i as i64))
            if rc != 0: return rc
    else:
        rc = sdk_check_file(ctx, sdk_join(prefix, "lib/libclang.a"), "static libclang archive")
        if rc != 0: return rc
        let tools: Vec[str] = Vec.new()
        tools.push("clang")
        tools.push("clang++")
        tools.push("cmake")
        tools.push("ninja")
        tools.push("lld")
        tools.push("llvm-nm")
        tools.push("llvm-readobj")
        tools.push("llvm-strip")
        for i in 0..tools.len() as i32:
            rc = sdk_check_file(ctx, sdk_required_tool(prefix, tools.get(i as i64)), tools.get(i as i64))
            if rc != 0: return rc
    let fs = ctx.fs()
    if not fs.is_dir(sdk_join(prefix, "lib/clang")):
        return sdk_fail(ctx, "missing clang builtin header tree: " ++ sdk_join(prefix, "lib/clang"))
    if not sdk_package_has_builtin_stddef(fs, prefix):
        return sdk_fail(ctx, "clang builtin header tree is missing include/stddef.h")
    0

fn sdk_package_has_builtin_stddef(fs: &ToolFs, prefix: str) -> bool:
    let files = fs.list_files(sdk_join(prefix, "lib/clang"))
    for i in 0..files.len() as i32:
        let path = sdk_normalize(files.get(i as i64))
        if path.ends_with("/include/stddef.h"):
            return true
    false

fn sdk_optional_tool_exists(fs: &ToolFs, prefix: str, name: str) -> bool:
    fs.exists(sdk_required_tool(prefix, name))

fn sdk_is_unix_lld_alias(rel: str) -> bool:
    rel == "bin/ld.lld" or rel == "bin/ld64.lld" or rel == "bin/lld-link" or rel == "bin/wasm-ld"

fn sdk_select_package_files(fs: &ToolFs, prefix: str, platform: str) -> Vec[str]:
    let selected: Vec[str] = Vec.new()
    let all = sdk_sort_strings(fs.list_files(prefix))
    for i in 0..all.len() as i32:
        let path = all.get(i as i64)
        let rel = sdk_rel_path(prefix, path)
        if rel.len() == 0:
            continue
        if platform != "windows-x86_64" and sdk_is_unix_lld_alias(rel):
            continue
        if rel.starts_with("lib/clang/"):
            selected.push(path)
        else if rel.starts_with("lib/"):
            let lib_rel = rel.slice(4, rel.len())
            if not sdk_has_slash(lib_rel):
                if platform == "windows-x86_64":
                    if rel.ends_with(".lib"):
                        selected.push(path)
                else if rel.ends_with(".a"):
                    selected.push(path)
        else if rel.starts_with("bin/"):
            if sdk_package_tool_selected(rel, platform):
                selected.push(path)
    selected

fn sdk_package_tool_selected(rel: str, platform: str) -> bool:
    let tools: Vec[str] = Vec.new()
    if platform == "windows-x86_64":
        tools.push("bin/clang.exe")
        tools.push("bin/clang++.exe")
        tools.push("bin/clang-cl.exe")
        tools.push("bin/cmake.exe")
        tools.push("bin/ninja.exe")
        tools.push("bin/lld-link.exe")
        tools.push("bin/llvm-lib.exe")
        tools.push("bin/llvm-ml.exe")
        tools.push("bin/llvm-ml64.exe")
        tools.push("bin/llvm-nm.exe")
        tools.push("bin/llvm-readobj.exe")
        tools.push("bin/llvm-strip.exe")
        tools.push("bin/ctest.exe")
        tools.push("bin/cpack.exe")
    else:
        tools.push("bin/clang")
        tools.push("bin/clang++")
        tools.push("bin/cmake")
        tools.push("bin/ninja")
        tools.push("bin/ctest")
        tools.push("bin/cpack")
        tools.push("bin/lld")
        tools.push("bin/llvm-nm")
        tools.push("bin/llvm-readobj")
        tools.push("bin/llvm-strip")
    for i in 0..tools.len() as i32:
        if rel == tools.get(i as i64):
            return true
    false

fn sdk_file_mode(rel: str) -> i32:
    if rel.starts_with("bin/"):
        return 0o755
    0o644

fn sdk_package_entries(ctx: &ActionCtx, prefix: str, sdk_base: str, platform: str) -> Vec[ArchiveEntry]:
    let fs = ctx.fs()
    let files = sdk_select_package_files(fs, prefix, platform)
    var dirs: Vec[str] = Vec.new()
    for i in 0..files.len() as i32:
        let rel = sdk_rel_path(prefix, files.get(i as i64))
        dirs = sdk_add_parent_dirs(dirs, sdk_base, rel)
    if platform != "windows-x86_64":
        let aliases: Vec[str] = Vec.new()
        aliases.push("ld.lld")
        aliases.push("ld64.lld")
        aliases.push("lld-link")
        aliases.push("wasm-ld")
        for i in 0..aliases.len() as i32:
            let alias = aliases.get(i as i64)
            if fs.exists(sdk_join(prefix, "bin/" ++ alias)):
                dirs = sdk_add_parent_dirs(dirs, sdk_base, "bin/" ++ alias)
    dirs = sdk_sort_strings(dirs)
    let entries: Vec[ArchiveEntry] = Vec.new()
    for i in 0..dirs.len() as i32:
        entries.push(archive_dir_entry(dirs.get(i as i64), 0o755))
    for i in 0..files.len() as i32:
        let path = files.get(i as i64)
        let rel = sdk_rel_path(prefix, path)
        entries.push(archive_file_entry(path, sdk_base ++ "/" ++ rel, sdk_file_mode(rel)))
    if platform != "windows-x86_64":
        let aliases: Vec[str] = Vec.new()
        aliases.push("ld.lld")
        aliases.push("ld64.lld")
        aliases.push("lld-link")
        aliases.push("wasm-ld")
        for i in 0..aliases.len() as i32:
            let alias = aliases.get(i as i64)
            if fs.exists(sdk_join(prefix, "bin/" ++ alias)):
                entries.push(archive_symlink_entry("lld", sdk_base ++ "/bin/" ++ alias, 0o777))
    entries

fn sdk_write_text(ctx: &ActionCtx, path: str, text: str) -> i32:
    let fs = ctx.fs()
    let dir = sdk_dirname(path)
    if dir != "." and fs.mkdir_all(dir) != 0:
        return sdk_fail(ctx, "could not create directory: " ++ dir)
    if fs.write_text(path, text) != 0:
        return sdk_fail(ctx, "could not write: " ++ path)
    0

fn sdk_archive_manifest(entries: &Vec[ArchiveEntry]) -> str:
    var out = ""
    for i in 0..entries.len() as i32:
        let entry = entries.get(i as i64)
        out = out ++ entry.archive_path ++ "\n"
    out

pub fn run_package_llvm_sdk_action(ctx: ActionCtx) -> i32:
    let args = ctx.args()
    if args.len() < 5:
        return sdk_fail(ctx, "requires platform, prefix, build-cache, asset, and sdk-base args")
    let platform = args.get(0)
    let prefix = args.get(1)
    let build_cache = args.get(2)
    let asset = args.get(3)
    let sdk_base = args.get(4)
    var rc = sdk_validate_package_prefix(ctx, platform, prefix, build_cache)
    if rc != 0:
        return rc
    let output_path = sdk_join("out/release", asset)
    let entries = sdk_package_entries(ctx, prefix, sdk_base, platform)
    if entries.len() == 0:
        return sdk_fail(ctx, "SDK package would be empty")
    if ctx.fs().mkdir_all("out/release") != 0:
        return sdk_fail(ctx, "could not create out/release")
    if ctx.fs().write_tar_gz(output_path, entries) != 0:
        return sdk_fail(ctx, "could not write SDK archive: " ++ output_path)
    let sha = ctx.fs().sha256_file(output_path)
    if sha.len() == 0:
        return sdk_fail(ctx, "could not hash SDK archive: " ++ output_path)
    rc = sdk_write_text(ctx, output_path ++ ".sha256", sha ++ "  " ++ output_path ++ "\n")
    if rc != 0:
        return rc
    rc = sdk_write_text(ctx, output_path ++ ".manifest", sdk_archive_manifest(entries))
    if rc != 0:
        return rc
    let stamp = ctx.output()
    if stamp.len() > 0:
        return sdk_write_text(ctx, stamp, "ok\n")
    0

fn sdk_compile_helper(ctx: &ActionCtx, workspace_name: str, source_path: str, output_path: str) -> i32:
    if ctx.fs().mkdir_all(sdk_dirname(output_path)) != 0:
        return sdk_fail(ctx, "could not create helper directory")
    let workspace = ctx.create_workspace(workspace_name)
    workspace.add_file(source_path)
    var options = workspace.options()
    options.output_path = output_path
    workspace.set_options(options)
    let result = workspace.compile()
    if result.rc != 0:
        return sdk_fail(ctx, workspace_name ++ f" failed with exit code {result.rc}")
    if not ctx.fs().exists(output_path):
        return sdk_fail(ctx, workspace_name ++ " did not produce " ++ output_path)
    0

fn sdk_fetch(ctx: &ActionCtx, scratch: str, label: str, url: str, output_path: str, timeout_ms: i32) -> i32:
    let root = ctx.project_info().project_root()
    let helper = sdk_join(scratch, "https_fetch" ++ sdk_exe_suffix())
    var rc = sdk_compile_helper(ctx, label ++ "-https-fetch-helper", "build/https_fetch.w", helper)
    if rc != 0:
        return rc
    let argv: Vec[str] = Vec.new()
    argv.push(sdk_abs(root, helper))
    argv.push(url)
    argv.push(sdk_abs(root, output_path))
    let result = ctx.process_runner().run_capture(argv, sdk_abs(root, sdk_join(scratch, label ++ ".fetch.stdout")), sdk_abs(root, sdk_join(scratch, label ++ ".fetch.stderr")), timeout_ms)
    if result.rc != 0:
        return sdk_fail(ctx, f"HTTPS fetch helper failed with exit code {result.rc}: " ++ result.stdout ++ result.stderr)
    0

fn sdk_gunzip(ctx: &ActionCtx, scratch: str, archive_path: str, tar_path: str) -> i32:
    let root = ctx.project_info().project_root()
    let helper = sdk_join(scratch, "zlib_gunzip" ++ sdk_exe_suffix())
    var rc = sdk_compile_helper(ctx, "sdk-source-gunzip-helper", "build/zlib_gunzip.w", helper)
    if rc != 0:
        return rc
    let argv: Vec[str] = Vec.new()
    argv.push(sdk_abs(root, helper))
    argv.push(sdk_abs(root, archive_path))
    argv.push(sdk_abs(root, tar_path))
    let result = ctx.process_runner().run_capture(argv, sdk_abs(root, sdk_join(scratch, "gunzip.stdout")), sdk_abs(root, sdk_join(scratch, "gunzip.stderr")), 900000)
    if result.rc != 0:
        return sdk_fail(ctx, f"gunzip helper failed with exit code {result.rc}: " ++ result.stdout ++ result.stderr)
    0

pub fn run_sdk_source_tar_gz_action(ctx: ActionCtx) -> i32:
    let args = ctx.args()
    let marker = ctx.output()
    if args.len() < 5 or marker.len() == 0:
        return sdk_fail(ctx, "requires url, sha256, archive, source-root, and source-dir args")
    let url = args.get(0)
    let expected_sha = args.get(1)
    let archive = args.get(2)
    let source_root = args.get(3)
    let source_dir = args.get(4)
    if expected_sha.len() == 0:
        return sdk_fail(ctx, "source download requires pinned SHA-256")
    let fs = ctx.fs()
    if fs.exists(marker):
        return 0
    if fs.mkdir_all(source_root) != 0:
        return sdk_fail(ctx, "could not create source root: " ++ source_root)
    let scratch = sdk_join("out/command", ctx.target_name())
    if fs.mkdir_all(scratch) != 0:
        return sdk_fail(ctx, "could not create command directory: " ++ scratch)
    if not fs.exists(archive):
        var rc = sdk_fetch(ctx, scratch, "source", url, archive, 1800000)
        if rc != 0:
            return rc
    let actual = fs.sha256_file(archive)
    if actual.len() == 0:
        return sdk_fail(ctx, "could not hash source archive: " ++ archive)
    if actual != expected_sha:
        return sdk_fail(ctx, "source archive sha256 mismatch for " ++ archive ++ ": expected " ++ expected_sha ++ " got " ++ actual)
    let tar_path = sdk_join(scratch, sdk_basename(source_dir) ++ ".tar")
    let _remove_tar = fs.remove_file(tar_path)
    var rc = sdk_gunzip(ctx, scratch, archive, tar_path)
    if rc != 0:
        return rc
    if fs.extract_tar(tar_path, source_root) != 0:
        return sdk_fail(ctx, "tar extraction failed for " ++ tar_path)
    if not fs.is_dir(source_dir):
        return sdk_fail(ctx, "source archive did not contain expected directory: " ++ source_dir)
    sdk_write_text(ctx, marker, "ok\n")

fn sdk_jobs_arg(jobs: str) -> Vec[str]:
    let out: Vec[str] = Vec.new()
    out.push("--parallel")
    if jobs.len() > 0:
        out.push(jobs)
    out

fn sdk_append_jobs(mut args: Vec[str], jobs: str) -> Vec[str]:
    args.push("--parallel")
    if jobs.len() > 0:
        args.push(jobs)
    args

fn sdk_run_capture(ctx: &ActionCtx, label: str, argv: Vec[str], timeout_ms: i32) -> i32:
    let root = ctx.project_info().project_root()
    let command_dir = sdk_join("out/command", ctx.target_name())
    let _mkdir = ctx.fs().mkdir_all(command_dir)
    let result = ctx.process_runner().run_capture(argv, sdk_abs(root, sdk_join(command_dir, label ++ ".stdout")), sdk_abs(root, sdk_join(command_dir, label ++ ".stderr")), timeout_ms)
    if result.rc != 0:
        return sdk_fail(ctx, label ++ f" failed with exit code {result.rc}: " ++ result.stdout ++ result.stderr)
    0

fn sdk_validate_staged_paths(ctx: &ActionCtx, bootstrap_prefix: str, output_prefix: str) -> i32:
    if sdk_is_abs(bootstrap_prefix) or sdk_is_abs(output_prefix):
        return sdk_fail(ctx, "SDK build prefixes must be project-relative graph paths")
    if sdk_normalize(bootstrap_prefix) == sdk_normalize(output_prefix):
        return sdk_fail(ctx, "SDK_OUTPUT_PREFIX must be different from SDK_BOOTSTRAP_PREFIX")
    if not ctx.fs().exists(sdk_tool(bootstrap_prefix, "clang")):
        return sdk_fail(ctx, "missing bootstrap SDK clang: " ++ sdk_tool(bootstrap_prefix, "clang"))
    if not ctx.fs().exists(sdk_tool(bootstrap_prefix, "clang++")):
        return sdk_fail(ctx, "missing bootstrap SDK clang++: " ++ sdk_tool(bootstrap_prefix, "clang++"))
    if not ctx.fs().exists(sdk_tool(bootstrap_prefix, "cmake")):
        return sdk_fail(ctx, "missing bootstrap SDK cmake: " ++ sdk_tool(bootstrap_prefix, "cmake"))
    if not ctx.fs().exists(sdk_tool(bootstrap_prefix, "ninja")):
        return sdk_fail(ctx, "missing bootstrap SDK ninja: " ++ sdk_tool(bootstrap_prefix, "ninja"))
    0

pub fn run_sdk_ninja_action(ctx: ActionCtx) -> i32:
    let args = ctx.args()
    if args.len() < 5:
        return sdk_fail(ctx, "requires bootstrap-prefix, output-prefix, source-dir, build-dir, and jobs args")
    let bootstrap_prefix = args.get(0)
    let output_prefix = args.get(1)
    let source_dir = args.get(2)
    let build_dir = args.get(3)
    let jobs = args.get(4)
    var rc = sdk_validate_staged_paths(ctx, bootstrap_prefix, output_prefix)
    if rc != 0:
        return rc
    let fs = ctx.fs()
    if fs.mkdir_all(build_dir) != 0 or fs.mkdir_all(sdk_join(output_prefix, "bin")) != 0:
        return sdk_fail(ctx, "could not create SDK Ninja build/output directories")
    let root = ctx.project_info().project_root()
    let cmake = sdk_abs(root, sdk_tool(bootstrap_prefix, "cmake"))
    let configure: Vec[str] = Vec.new()
    configure.push(cmake)
    configure.push("-G")
    configure.push("Ninja")
    configure.push("-S")
    configure.push(sdk_abs(root, source_dir))
    configure.push("-B")
    configure.push(sdk_abs(root, build_dir))
    configure.push("-DCMAKE_BUILD_TYPE=Release")
    configure.push("-DCMAKE_CXX_COMPILER=" ++ sdk_abs(root, sdk_tool(bootstrap_prefix, "clang++")))
    configure.push("-DCMAKE_INSTALL_PREFIX=" ++ sdk_abs(root, output_prefix))
    configure.push("-DCMAKE_MAKE_PROGRAM=" ++ sdk_abs(root, sdk_tool(bootstrap_prefix, "ninja")))
    configure.push("-DBUILD_TESTING=OFF")
    rc = sdk_run_capture(ctx, "ninja-configure", configure, 300000)
    if rc != 0: return rc
    var build: Vec[str] = Vec.new()
    build.push(cmake)
    build.push("--build")
    build.push(sdk_abs(root, build_dir))
    build.push("--target")
    build.push("install")
    build = sdk_append_jobs(build, jobs)
    rc = sdk_run_capture(ctx, "ninja-build", build, 900000)
    if rc != 0: return rc
    let installed = sdk_tool(output_prefix, "ninja")
    if not fs.exists(installed):
        let built = sdk_join(build_dir, sdk_exe_name("ninja"))
        if not fs.exists(built):
            return sdk_fail(ctx, "Ninja build did not produce " ++ installed ++ " or " ++ built)
        if fs.copy_file(built, installed) != 0:
            return sdk_fail(ctx, "could not install Ninja to " ++ installed)
        let _chmod = fs.chmod(installed, 0o755)
    if not fs.exists(installed):
        return sdk_fail(ctx, "Ninja did not install to " ++ installed)
    0

pub fn run_sdk_cmake_action(ctx: ActionCtx) -> i32:
    let args = ctx.args()
    if args.len() < 5:
        return sdk_fail(ctx, "requires bootstrap-prefix, output-prefix, source-dir, build-dir, and jobs args")
    let bootstrap_prefix = args.get(0)
    let output_prefix = args.get(1)
    let source_dir = args.get(2)
    let build_dir = args.get(3)
    let jobs = args.get(4)
    var rc = sdk_validate_staged_paths(ctx, bootstrap_prefix, output_prefix)
    if rc != 0:
        return rc
    let fs = ctx.fs()
    if not fs.exists(sdk_tool(output_prefix, "ninja")):
        return sdk_fail(ctx, "missing staged Ninja: " ++ sdk_tool(output_prefix, "ninja"))
    if fs.mkdir_all(build_dir) != 0:
        return sdk_fail(ctx, "could not create CMake build directory: " ++ build_dir)
    let root = ctx.project_info().project_root()
    let cmake = sdk_abs(root, sdk_tool(bootstrap_prefix, "cmake"))
    let configure: Vec[str] = Vec.new()
    configure.push(cmake)
    configure.push("-G")
    configure.push("Ninja")
    configure.push("-S")
    configure.push(sdk_abs(root, source_dir))
    configure.push("-B")
    configure.push(sdk_abs(root, build_dir))
    configure.push("-DCMAKE_BUILD_TYPE=Release")
    configure.push("-DCMAKE_INSTALL_PREFIX=" ++ sdk_abs(root, output_prefix))
    configure.push("-DCMAKE_C_COMPILER=" ++ sdk_abs(root, sdk_tool(bootstrap_prefix, "clang")))
    configure.push("-DCMAKE_CXX_COMPILER=" ++ sdk_abs(root, sdk_tool(bootstrap_prefix, "clang++")))
    configure.push("-DCMAKE_MAKE_PROGRAM=" ++ sdk_abs(root, sdk_tool(output_prefix, "ninja")))
    configure.push("-DBUILD_TESTING=OFF")
    configure.push("-DCMAKE_USE_OPENSSL=OFF")
    if os() == "Windows":
        configure.push("-DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreaded")
        configure.push("-DCMAKE_LINKER=" ++ sdk_abs(root, sdk_tool(bootstrap_prefix, "lld-link")))
    rc = sdk_run_capture(ctx, "cmake-configure", configure, 600000)
    if rc != 0: return rc
    var build: Vec[str] = Vec.new()
    build.push(cmake)
    build.push("--build")
    build.push(sdk_abs(root, build_dir))
    if os() == "Windows":
        build.push("--config")
        build.push("Release")
    build.push("--target")
    build.push("install")
    build = sdk_append_jobs(build, jobs)
    rc = sdk_run_capture(ctx, "cmake-build", build, 3600000)
    if rc != 0: return rc
    if not fs.exists(sdk_tool(output_prefix, "cmake")):
        return sdk_fail(ctx, "CMake did not install to " ++ sdk_tool(output_prefix, "cmake"))
    0

fn sdk_llvm_targets_arg(ctx: &ActionCtx, requested: str) -> str:
    if requested.len() > 0:
        return requested
    "AArch64;X86"

pub fn run_sdk_llvm_action(ctx: ActionCtx) -> i32:
    let args = ctx.args()
    if args.len() < 9:
        return sdk_fail(ctx, "requires bootstrap-prefix, output-prefix, source-dir, build-dir, jobs, targets, sdkroot, deployment-target, and windows-mt args")
    let bootstrap_prefix = args.get(0)
    let output_prefix = args.get(1)
    let source_dir = args.get(2)
    let build_dir = args.get(3)
    let jobs = args.get(4)
    let targets = sdk_llvm_targets_arg(ctx, args.get(5))
    let sdkroot = args.get(6)
    let deployment_target = if args.get(7).len() > 0: args.get(7) else: "11.0"
    let windows_mt = args.get(8)
    var rc = sdk_validate_staged_paths(ctx, bootstrap_prefix, output_prefix)
    if rc != 0:
        return rc
    let fs = ctx.fs()
    if not fs.exists(sdk_tool(output_prefix, "cmake")):
        return sdk_fail(ctx, "missing staged CMake: " ++ sdk_tool(output_prefix, "cmake"))
    if not fs.exists(sdk_tool(output_prefix, "ninja")):
        return sdk_fail(ctx, "missing staged Ninja: " ++ sdk_tool(output_prefix, "ninja"))
    if fs.mkdir_all(build_dir) != 0:
        return sdk_fail(ctx, "could not create LLVM build directory: " ++ build_dir)
    let root = ctx.project_info().project_root()
    let cmake = sdk_abs(root, sdk_tool(output_prefix, "cmake"))
    let configure: Vec[str] = Vec.new()
    configure.push(cmake)
    configure.push("-G")
    configure.push("Ninja")
    configure.push("-S")
    configure.push(sdk_abs(root, sdk_join(source_dir, "llvm")))
    configure.push("-B")
    configure.push(sdk_abs(root, build_dir))
    configure.push("-DCMAKE_BUILD_TYPE=Release")
    configure.push("-DCMAKE_INSTALL_PREFIX=" ++ sdk_abs(root, output_prefix))
    configure.push("-DCMAKE_MAKE_PROGRAM=" ++ sdk_abs(root, sdk_tool(output_prefix, "ninja")))
    configure.push("-DLLVM_ENABLE_PROJECTS=clang;lld")
    configure.push("-DLLVM_TARGETS_TO_BUILD=" ++ targets)
    configure.push("-DLIBCLANG_BUILD_STATIC=ON")
    configure.push("-DBUILD_SHARED_LIBS=OFF")
    configure.push("-DLLVM_BUILD_LLVM_DYLIB=OFF")
    configure.push("-DLLVM_LINK_LLVM_DYLIB=OFF")
    configure.push("-DCLANG_LINK_CLANG_DYLIB=OFF")
    configure.push("-DLLVM_INCLUDE_TESTS=OFF")
    configure.push("-DLLVM_INCLUDE_BENCHMARKS=OFF")
    configure.push("-DLLVM_INCLUDE_EXAMPLES=OFF")
    configure.push("-DCLANG_INCLUDE_TESTS=OFF")
    configure.push("-DCLANG_BUILD_EXAMPLES=OFF")
    configure.push("-DLLVM_ENABLE_ZLIB=OFF")
    configure.push("-DLLVM_ENABLE_ZSTD=OFF")
    if os() == "Windows":
        configure.push("-DCMAKE_C_COMPILER=" ++ sdk_abs(root, sdk_tool(bootstrap_prefix, "clang-cl")))
        configure.push("-DCMAKE_CXX_COMPILER=" ++ sdk_abs(root, sdk_tool(bootstrap_prefix, "clang-cl")))
        configure.push("-DCMAKE_LINKER=" ++ sdk_abs(root, sdk_tool(bootstrap_prefix, "lld-link")))
        configure.push("-DCMAKE_ASM_MASM_COMPILER=" ++ sdk_abs(root, sdk_tool(bootstrap_prefix, "llvm-ml64")))
        configure.push("-DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreaded")
        configure.push("-DLLVM_ENABLE_PIC=OFF")
        configure.push("-DLLVM_ENABLE_DIA_SDK=OFF")
        if windows_mt.len() == 0:
            return sdk_fail(ctx, "SDK_WINDOWS_MT must name the Windows SDK mt.exe path for Windows SDK rebuilds")
        configure.push("-DCMAKE_MT=" ++ windows_mt)
    else:
        configure.push("-DCMAKE_C_COMPILER=" ++ sdk_abs(root, sdk_tool(bootstrap_prefix, "clang")))
        configure.push("-DCMAKE_CXX_COMPILER=" ++ sdk_abs(root, sdk_tool(bootstrap_prefix, "clang++")))
        configure.push("-DCMAKE_EXE_LINKER_FLAGS_INIT=-fuse-ld=lld")
        configure.push("-DCMAKE_MODULE_LINKER_FLAGS_INIT=-fuse-ld=lld")
        configure.push("-DCMAKE_SHARED_LINKER_FLAGS_INIT=-fuse-ld=lld")
        configure.push("-DLLVM_ENABLE_PIC=ON")
        if os() == "Macos":
            if sdkroot.len() == 0:
                return sdk_fail(ctx, "SDKROOT must be set for macOS SDK rebuilds; the graph will not shell out to xcrun")
            configure.push("-DCMAKE_OSX_SYSROOT=" ++ sdkroot)
            configure.push("-DCMAKE_OSX_DEPLOYMENT_TARGET=" ++ deployment_target)
            if arch() == "armv8" or arch() == "aarch64":
                configure.push("-DCMAKE_OSX_ARCHITECTURES=arm64")
            else if arch() == "x86_64":
                configure.push("-DCMAKE_OSX_ARCHITECTURES=x86_64")
            else:
                return sdk_fail(ctx, "unsupported macOS arch: " ++ arch())
    rc = sdk_run_capture(ctx, "llvm-configure", configure, 1800000)
    if rc != 0: return rc
    var build: Vec[str] = Vec.new()
    build.push(cmake)
    build.push("--build")
    build.push(sdk_abs(root, build_dir))
    if os() == "Windows":
        build.push("--config")
        build.push("Release")
    build.push("--target")
    build.push("install")
    build = sdk_append_jobs(build, jobs)
    rc = sdk_run_capture(ctx, "llvm-build", build, 21600000)
    if rc != 0: return rc
    let libclang = if os() == "Windows": sdk_join(output_prefix, "lib/libclang.lib") else: sdk_join(output_prefix, "lib/libclang.a")
    if not fs.exists(libclang):
        return sdk_fail(ctx, "static libclang archive was not installed: " ++ libclang)
    if not fs.exists(sdk_tool(output_prefix, "clang")):
        return sdk_fail(ctx, "clang driver was not installed: " ++ sdk_tool(output_prefix, "clang"))
    if not fs.exists(sdk_tool(output_prefix, "llvm-nm")):
        return sdk_fail(ctx, "llvm-nm was not installed: " ++ sdk_tool(output_prefix, "llvm-nm"))
    0
