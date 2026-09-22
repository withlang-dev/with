module build.sdk

use std.build
use std.string.StringBuilder
use std.sysinfo
use build.compiler
fn sdk_owned_text(s: &str): s ++ ""

const SDK_NINJA_VERSION: str = "1.13.1"
const SDK_NINJA_SHA256: str = "f0055ad0369bf2e372955ba55128d000cfcc21777057806015b45e4accbebf23"
const SDK_CMAKE_VERSION: str = "4.2.3"
const SDK_CMAKE_SHA256: str = "7efaccde8c5a6b2968bad6ce0fe60e19b6e10701a12fce948c2bf79bac8a11e9"
const SDK_LLVM_TAG_TAR_GZ_SHA256: str = "ba534c6835a5b9c2162c806e269799fe41fca952a3c25baff1afcff23841ec2b"

fn sdk_fail(ctx: &ActionCtx, message: &str) -> i32:
    ctx.diagnostics().error(ctx.target_name() ++ ": " ++ message)
    1

fn sdk_join(left: &str, right: &str) -> str:
    if left.len() == 0:
        return sdk_owned_text(right)
    if right.len() == 0:
        return sdk_owned_text(left)
    if left.ends_with("/") or left.ends_with("\\"):
        return left ++ right
    left ++ "/" ++ right

fn sdk_dirname(path: &str) -> str:
    var last_slash = -1
    for i in 0..path.len() as i32:
        let ch = path[i]
        if ch == 47 or ch == 92:
            last_slash = i
    if last_slash < 0:
        return "."
    if last_slash == 0:
        return "/"
    path.slice(0, last_slash as i64)

fn sdk_is_abs(path: &str) -> bool:
    if path.len() == 0:
        return false
    if path[0] == 47 or path[0] == 92:
        return true
    if os() == "Windows" and path.len() >= 3:
        let drive = path[0]
        let colon = path[1]
        let slash = path[2]
        if colon == 58 and (slash == 47 or slash == 92):
            return (drive >= 65 and drive <= 90) or (drive >= 97 and drive <= 122)
    false

fn sdk_abs(root: &str, path: &str) -> str:
    if sdk_is_abs(path):
        return sdk_owned_text(path)
    sdk_join(root, path)

fn sdk_normalize(path: &str) -> str:
    var out = StringBuilder.with_capacity(path.len())
    for i in 0..path.len() as i32:
        let ch = path[i]
        if ch == 92:
            out.push_byte(47 as u8)
        else:
            out.push_byte(ch as u8)
    out.to_str()

fn sdk_basename(path: &str) -> str:
    var last_slash: i64 = -1
    for i in 0..path.len() as i32:
        let ch = path[i]
        if ch == 47 or ch == 92:
            last_slash = i as i64
    if last_slash >= 0:
        return path.slice(last_slash + 1, path.len())
    sdk_owned_text(path)

fn sdk_rel_path(root: &str, path: &str) -> str:
    let nr = sdk_normalize(root)
    let np = sdk_normalize(path)
    let prefix = if nr.ends_with("/"): nr else: nr ++ "/"
    if np.starts_with(prefix):
        return np.slice(prefix.len(), np.len())
    ""

fn sdk_has_slash(text: &str) -> bool:
    text.find("/") >= 0 or text.find("\\") >= 0

fn sdk_exe_suffix() -> str:
    if os() == "Windows":
        return ".exe"
    ""

fn sdk_exe_name(name: &str) -> str:
    if os() == "Windows" and not name.ends_with(".exe"):
        return name ++ ".exe"
    sdk_owned_text(name)

pub fn sdk_current_platform() -> str:
    if os() == "Macos" and comp_arch_is_aarch64(arch()):
        return "darwin-aarch64"
    if os() == "Linux" and arch() == "x86_64":
        return "linux-x86_64"
    if os() == "Linux" and comp_arch_is_aarch64(arch()):
        return "linux-aarch64"
    if os() == "Windows" and arch() == "x86_64":
        return "windows-x86_64"
    if os() == "Windows" and (arch() == "armv8" or arch() == "aarch64"):
        return "windows-aarch64"
    ""

pub fn sdk_host_tag_for_platform(platform: &str) -> str:
    if platform == "darwin-aarch64":
        return "darwin-arm64"
    if platform == "linux-x86_64":
        return "linux-x86_64"
    if platform == "linux-aarch64":
        return "linux-aarch64"
    if platform == "windows-x86_64":
        return "windows-x86_64-msvc"
    if platform == "windows-aarch64":
        return "windows-aarch64-msvc"
    "unsupported"

fn sdk_platform_is_windows(platform: &str) -> bool:
    platform == "windows-x86_64" or platform == "windows-aarch64"

pub fn sdk_default_prefix_for_platform(platform: &str) -> str:
    ".deps/llvm-" ++ compiler_llvm_version() ++ "-" ++ sdk_host_tag_for_platform(platform)

pub fn sdk_default_build_cache_for_platform(platform: &str) -> str:
    ".deps/build/llvm-" ++ compiler_llvm_version() ++ "-" ++ sdk_host_tag_for_platform(platform) ++ "/CMakeCache.txt"

pub fn sdk_asset_for_platform(platform: &str) -> str:
    "with-llvm-sdk-" ++ compiler_llvm_version() ++ "-" ++ platform ++ ".tar.gz"

pub fn sdk_output_prefix_for_platform(platform: &str) -> str:
    "out/sdk/" ++ sdk_host_tag_for_platform(platform) ++ "/install/llvm-" ++ compiler_llvm_version() ++ "-" ++ sdk_host_tag_for_platform(platform)

pub fn sdk_output_build_root_for_platform(platform: &str) -> str:
    "out/sdk/" ++ sdk_host_tag_for_platform(platform) ++ "/build"

pub fn sdk_output_llvm_cache_for_platform(platform: &str) -> str:
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

fn sdk_str_compare(a: &str, b: &str) -> i32:
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

fn sdk_sort_strings(items: Vec[str]) -> Vec[str]:
    var sorted: Vec[str] = Vec.new()
    for i in 0..items.len() as i32:
        let item = items[i]
        var inserted = false
        var out: Vec[str] = Vec.new()
        for j in 0..sorted.len() as i32:
            let existing = sorted[j]
            if not inserted and sdk_str_compare(item, existing) < 0:
                out.push(sdk_owned_text(item))
                inserted = true
            out.push(sdk_owned_text(existing))
        if not inserted:
            out.push(sdk_owned_text(item))
        sorted = out
    sorted

fn sdk_add_unique(items: Vec[str], item: &str) -> Vec[str]:
    var out = items
    for i in 0..out.len() as i32:
        if out[i] == item:
            return out
    out.push(sdk_owned_text(item))
    out

fn sdk_add_parent_dirs(dirs: Vec[str], top_dir: &str, rel_path: &str) -> Vec[str]:
    var out = sdk_add_unique(move dirs, top_dir)
    for i in 0..rel_path.len() as i32:
        if rel_path[i] == 47:
            out = sdk_add_unique(move out, top_dir ++ "/" ++ rel_path.slice(0, i as i64))
    out

fn sdk_file_exists(fs: &ToolFs, path: &str) -> bool:
    fs.exists(path)

fn sdk_required_tool(prefix: &str, name: &str) -> str:
    sdk_join(prefix, "bin/" ++ sdk_exe_name(name))

fn sdk_tool(prefix: &str, name: &str) -> str:
    sdk_join(prefix, "bin/" ++ sdk_exe_name(name))

fn sdk_check_file(ctx: &ActionCtx, path: &str, label: &str) -> i32:
    let fs = ctx.fs()
    if not sdk_file_exists(fs, path):
        return sdk_fail(ctx, "missing " ++ label ++ ": " ++ path)
    0

fn sdk_cache_line(cache: &str, key: &str) -> str:
    let lines = sdk_split_lines(cache)
    for i in 0..lines.len() as i32:
        let line = lines[i]
        if line.starts_with(key):
            return sdk_owned_text(line)
    ""

fn sdk_split_lines(text: &str) -> Vec[str]:
    let out: Vec[str] = Vec.new()
    var start = 0
    for i in 0..text.len() as i32:
        if text[i] == 10:
            out.push(text.slice(start as i64, i as i64))
            start = i + 1
    if start <= text.len() as i32:
        out.push(text.slice(start as i64, text.len()))
    out

fn sdk_validate_cache(ctx: &ActionCtx, platform: &str, cache_path: &str) -> i32:
    let fs = ctx.fs()
    if not fs.exists(cache_path):
        return sdk_fail(ctx, "missing SDK build cache: " ++ cache_path)
    let cache = fs.read_text(cache_path)
    let targets = sdk_cache_line(cache, "LLVM_TARGETS_TO_BUILD:")
    let equal = targets.find("=")
    if equal < 0 or not sdk_targets_include_wasm(targets.slice(equal + 1, targets.len())):
        return sdk_fail(ctx, "refusing to package SDK without the WebAssembly backend; " ++ targets)
    let cc = sdk_cache_line(cache, "CMAKE_C_COMPILER:")
    let cxx = sdk_cache_line(cache, "CMAKE_CXX_COMPILER:")
    if sdk_platform_is_windows(platform):
        if not cc.contains("clang-cl") or not cxx.contains("clang-cl"):
            return sdk_fail(ctx, "refusing to package SDK not built with clang-cl; CMAKE_C_COMPILER=" ++ cc ++ " CMAKE_CXX_COMPILER=" ++ cxx)
        if platform == "windows-x86_64":
            let masm = sdk_cache_line(cache, "CMAKE_ASM_MASM_COMPILER:")
            if not masm.contains("llvm-ml64"):
                return sdk_fail(ctx, "refusing to package SDK not built with llvm-ml64; CMAKE_ASM_MASM_COMPILER=" ++ masm)
        return 0
    if not cc.contains("clang") or cc.contains("/usr/bin/cc") or cc.contains("/usr/bin/gcc"):
        return sdk_fail(ctx, "refusing to package SDK not built with clang; CMAKE_C_COMPILER=" ++ cc)
    if not cxx.contains("clang++") or cxx.contains("/usr/bin/c++") or cxx.contains("/usr/bin/g++"):
        return sdk_fail(ctx, "refusing to package SDK not built with clang++; CMAKE_CXX_COMPILER=" ++ cxx)
    0

fn sdk_validate_package_prefix(ctx: &ActionCtx, platform: &str, prefix: &str, build_cache: &str) -> i32:
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
    if sdk_platform_is_windows(platform):
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
            rc = sdk_check_file(ctx, sdk_required_tool(prefix, tools[i]), tools[i])
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
            rc = sdk_check_file(ctx, sdk_required_tool(prefix, tools[i]), tools[i])
            if rc != 0: return rc
    rc = sdk_check_file(ctx, sdk_clang_main_archive(prefix), "clang driver archive (with cc)")
    if rc != 0: return rc
    rc = sdk_validate_wasm_install(ctx, prefix)
    if rc != 0: return rc
    rc = sdk_check_file(ctx, sdk_join(prefix, sdk_cmake_data_prefix() ++ "Modules/CMake.cmake"), "CMake runtime modules")
    if rc != 0: return rc
    let fs = ctx.fs()
    if not fs.is_dir(sdk_join(prefix, "lib/clang")):
        return sdk_fail(ctx, "missing clang builtin header tree: " ++ sdk_join(prefix, "lib/clang"))
    if not sdk_package_has_builtin_stddef(fs, prefix):
        return sdk_fail(ctx, "clang builtin header tree is missing include/stddef.h")
    0

fn sdk_validate_wasm_install(ctx: &ActionCtx, prefix: &str) -> i32:
    var rc = sdk_check_file(ctx, sdk_tool(prefix, "wasm-ld"), "WebAssembly linker")
    if rc != 0: return rc
    let linker_archive = if os() == "Windows": "lib/lldWasm.lib" else: "lib/liblldWasm.a"
    rc = sdk_check_file(ctx, sdk_join(prefix, linker_archive), "static WebAssembly linker archive")
    if rc != 0: return rc
    let components: Vec[str] = Vec.new()
    components.push("AsmParser")
    components.push("CodeGen")
    components.push("Desc")
    components.push("Disassembler")
    components.push("Info")
    components.push("Utils")
    for i in 0..components.len() as i32:
        let name = "LLVMWebAssembly" ++ components[i]
        let archive = if os() == "Windows": name ++ ".lib" else: "lib" ++ name ++ ".a"
        rc = sdk_check_file(ctx, sdk_join(prefix, "lib/" ++ archive), "static WebAssembly backend archive")
        if rc != 0: return rc
    0

fn sdk_package_has_builtin_stddef(fs: &ToolFs, prefix: &str) -> bool:
    let files = fs.list_files(sdk_join(prefix, "lib/clang"))
    for i in 0..files.len() as i32:
        let path = sdk_normalize(files[i])
        if path.ends_with("/include/stddef.h"):
            return true
    false

fn sdk_optional_tool_exists(fs: &ToolFs, prefix: &str, name: &str) -> bool:
    fs.exists(sdk_required_tool(prefix, name))

fn sdk_is_unix_lld_alias(rel: &str) -> bool:
    rel == "bin/ld.lld" or rel == "bin/ld64.lld" or rel == "bin/lld-link" or rel == "bin/wasm-ld"

fn sdk_cmake_data_prefix() -> str:
    let version = SDK_CMAKE_VERSION.split(".")
    "share/cmake-" ++ version[0] ++ "." ++ version[1] ++ "/"

fn sdk_select_package_files(fs: &ToolFs, prefix: &str, platform: &str) -> Vec[str]:
    let selected: Vec[str] = Vec.new()
    // Enumerate the shipped subtrees directly. A symlinked prefix is
    // an ancestor here, not the final lstat leaf, so it is followed normally.
    // LLVM's development headers outside lib/clang are not package inputs.
    var candidates = fs.list_files(sdk_join(prefix, "bin"))
    let libraries = fs.list_files(sdk_join(prefix, "lib"))
    for i in 0..libraries.len() as i32:
        candidates.push(sdk_owned_text(libraries[i]))
    let cmake_data = fs.list_files(sdk_join(prefix, "share"))
    for i in 0..cmake_data.len() as i32:
        candidates.push(sdk_owned_text(cmake_data[i]))
    let all = sdk_sort_strings(candidates)
    for i in 0..all.len() as i32:
        let path = all[i]
        let rel = sdk_rel_path(prefix, path)
        if rel.len() == 0:
            continue
        if not sdk_platform_is_windows(platform) and sdk_is_unix_lld_alias(rel):
            continue
        if rel.starts_with("lib/clang/") or rel.starts_with(sdk_cmake_data_prefix()):
            selected.push(sdk_owned_text(path))
        else if rel.starts_with("lib/"):
            let lib_rel = rel.slice(4, rel.len())
            if not sdk_has_slash(lib_rel):
                if sdk_platform_is_windows(platform):
                    if rel.ends_with(".lib"):
                        selected.push(sdk_owned_text(path))
                else if rel.ends_with(".a"):
                    selected.push(sdk_owned_text(path))
        else if rel.starts_with("bin/"):
            if sdk_package_tool_selected(rel, platform):
                selected.push(sdk_owned_text(path))
    selected

fn sdk_package_tool_selected(rel: &str, platform: &str) -> bool:
    let tools: Vec[str] = Vec.new()
    if sdk_platform_is_windows(platform):
        tools.push("bin/clang.exe")
        tools.push("bin/clang++.exe")
        tools.push("bin/clang-cl.exe")
        tools.push("bin/cmake.exe")
        // The Ninja generator's RC dependency scanner; cmake looks for it
        // beside cmake.exe and, when it is absent, silently emits the RC
        // rule without it, so rc.exe gets the scanner's arguments (RC1107).
        tools.push("bin/cmcldeps.exe")
        tools.push("bin/ninja.exe")
        tools.push("bin/lld-link.exe")
        tools.push("bin/wasm-ld.exe")
        tools.push("bin/llvm-lib.exe")
        tools.push("bin/llvm-ml.exe")
        tools.push("bin/llvm-ml64.exe")
        tools.push("bin/llvm-nm.exe")
        tools.push("bin/llvm-readobj.exe")
        tools.push("bin/llvm-strip.exe")
        tools.push("bin/ctest.exe")
        tools.push("bin/cpack.exe")
    else:
        // LLVM installs the driver as `clang-<major>` and links `clang` and
        // `clang++` to it. A package that keeps the links without their
        // target cannot bootstrap the next SDK (the v0.15.1 linux x86_64
        // asset: `bin/clang -> clang-22`, no clang-22) — select all three.
        tools.push("bin/clang")
        tools.push("bin/clang++")
        tools.push(sdk_clang_driver_rel())
        tools.push("bin/cmake")
        tools.push("bin/ninja")
        tools.push("bin/ctest")
        tools.push("bin/cpack")
        tools.push("bin/lld")
        tools.push("bin/llvm-nm")
        tools.push("bin/llvm-readobj")
        tools.push("bin/llvm-strip")
    for i in 0..tools.len() as i32:
        if rel == tools[i]:
            return true
    false

// The versioned clang driver binary the `clang`/`clang++` links resolve to.
fn sdk_clang_driver_rel() -> str: "bin/clang-" ++ COMPILER_LLVM_VERSION.split(".")[0]

// Everything the next SDK build needs from this package as its bootstrap
// (sdk_validate_staged_paths asks for exactly these): the compiler driver,
// its links, CMake with its module tree and RC scanner, and Ninja; on
// Windows also the MSVC-style driver and linker cmake's own build uses.
fn sdk_bootstrap_set(platform: &str) -> Vec[str]:
    let set: Vec[str] = Vec.new()
    if sdk_platform_is_windows(platform):
        set.push("bin/clang.exe")
        set.push("bin/clang++.exe")
        set.push("bin/clang-cl.exe")
        set.push("bin/lld-link.exe")
        set.push("bin/cmake.exe")
        set.push("bin/cmcldeps.exe")
        set.push("bin/ninja.exe")
    else:
        set.push("bin/clang")
        set.push("bin/clang++")
        set.push(sdk_clang_driver_rel())
        set.push("bin/cmake")
        set.push("bin/ninja")
    set.push(sdk_cmake_data_prefix() ++ "Modules/CMakeDetermineSystem.cmake")
    set

fn sdk_file_mode(rel: &str) -> i32:
    if rel.starts_with("bin/"):
        return 0o755
    0o644

fn sdk_package_entries(ctx: &ActionCtx, prefix: &str, sdk_base: &str, platform: &str) -> Vec[ArchiveEntry]:
    let fs = ctx.fs()
    let files = sdk_select_package_files(fs, prefix, platform)
    var dirs: Vec[str] = Vec.new()
    for i in 0..files.len() as i32:
        let rel = sdk_rel_path(prefix, files[i])
        dirs = sdk_add_parent_dirs(move dirs, sdk_base, rel)
    if not sdk_platform_is_windows(platform):
        let aliases: Vec[str] = Vec.new()
        aliases.push("ld.lld")
        aliases.push("ld64.lld")
        aliases.push("lld-link")
        aliases.push("wasm-ld")
        for i in 0..aliases.len() as i32:
            let alias = aliases[i]
            if fs.exists(sdk_join(prefix, "bin/" ++ alias)):
                dirs = sdk_add_parent_dirs(move dirs, sdk_base, "bin/" ++ alias)
    dirs = sdk_sort_strings(dirs)
    let entries: Vec[ArchiveEntry] = Vec.new()
    for i in 0..dirs.len() as i32:
        entries.push(archive_dir_entry(sdk_owned_text(dirs[i]), 0o755))
    for i in 0..files.len() as i32:
        let path = files[i]
        let rel = sdk_rel_path(prefix, path)
        entries.push(archive_file_entry(sdk_owned_text(path), sdk_base ++ "/" ++ rel, sdk_file_mode(rel)))
    if not sdk_platform_is_windows(platform):
        let aliases: Vec[str] = Vec.new()
        aliases.push("ld.lld")
        aliases.push("ld64.lld")
        aliases.push("lld-link")
        aliases.push("wasm-ld")
        for i in 0..aliases.len() as i32:
            let alias = aliases[i]
            if fs.exists(sdk_join(prefix, "bin/" ++ alias)):
                entries.push(archive_symlink_entry("lld", sdk_base ++ "/bin/" ++ alias, 0o777))
    entries

// The resource compiler of the same Windows Kit as mt.exe (they share
// bin/<version>/<arch>/). Left to PATH, CMake found a 2015 rc.exe that
// rejects its flags: `fatal error RC1107: invalid usage` compiling
// CMakeVersion.rc on both Windows lanes.
fn sdk_windows_rc_from_mt(windows_mt: &str) -> str: sdk_dirname(windows_mt) ++ "/rc.exe"

fn sdk_write_text(ctx: &ActionCtx, path: &str, text: &str) -> i32:
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
        let entry = entries[i]
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
    // Validate what will actually be written, not just the source prefix.
    // In particular, linker aliases alone do not make a usable SDK.
    let selected = sdk_archive_manifest(entries)
    let clang = if sdk_platform_is_windows(platform): "lib/libclang.lib" else: "lib/libclang.a"
    let lld = if sdk_platform_is_windows(platform): "bin/lld-link.exe" else: "bin/lld"
    let wasm = if sdk_platform_is_windows(platform): "bin/wasm-ld.exe" else: "bin/wasm-ld"
    if not selected.contains(sdk_base ++ "/" ++ clang ++ "\n") or not selected.contains(sdk_base ++ "/" ++ lld ++ "\n") or not selected.contains(sdk_base ++ "/" ++ wasm ++ "\n"):
        return sdk_fail(ctx, "SDK archive selection omitted required libraries or linkers")
    if not selected.contains(sdk_base ++ "/" ++ sdk_cmake_data_prefix() ++ "Modules/CMake.cmake\n"):
        return sdk_fail(ctx, "SDK archive selection omitted CMake runtime modules")
    // The archive is the next build's bootstrap; a package that cannot
    // bootstrap is not an SDK, whatever else it contains.
    let bootstrap = sdk_bootstrap_set(platform)
    for i in 0..bootstrap.len() as i32:
        if not selected.contains(sdk_base ++ "/" ++ bootstrap[i] ++ "\n"):
            return sdk_fail(ctx, "SDK archive cannot bootstrap the next SDK build: missing " ++ bootstrap[i] ++ " (the staged prefix lacks it, or the selection skipped it)")
    let source_libs = ctx.fs().list_files(sdk_join(prefix, "lib/"))
    for i in 0..source_libs.len() as i32:
        let rel = sdk_rel_path(prefix, source_libs[i])
        if rel.starts_with("lib/LLVMWebAssembly") or rel.starts_with("lib/libLLVMWebAssembly"):
            if not selected.contains(sdk_base ++ "/" ++ rel ++ "\n"):
                return sdk_fail(ctx, "SDK archive selection omitted " ++ rel)
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

fn sdk_compile_helper(ctx: &ActionCtx, workspace_name: &str, source_path: &str, output_path: &str) -> i32:
    if ctx.fs().mkdir_all(sdk_dirname(output_path)) != 0:
        return sdk_fail(ctx, "could not create helper directory")
    let workspace = ctx.create_workspace(workspace_name)
    workspace.add_file(source_path)
    var options = workspace.options()
    options.output_path = sdk_owned_text(output_path)
    workspace.set_options(options)
    let result = workspace.compile()
    if result.rc != 0:
        return sdk_fail(ctx, workspace_name ++ f" failed with exit code {result.rc}")
    if not ctx.fs().exists(output_path):
        return sdk_fail(ctx, workspace_name ++ " did not produce " ++ output_path)
    0

fn sdk_fetch(ctx: &ActionCtx, scratch: &str, label: &str, url: &str, output_path: &str, timeout_ms: i32) -> i32:
    let root = ctx.project_info().project_root()
    let helper = sdk_join(scratch, "https_fetch" ++ sdk_exe_suffix())
    var rc = sdk_compile_helper(ctx, label ++ "-https-fetch-helper", "build/https_fetch.w", helper)
    if rc != 0:
        return rc
    let argv: Vec[str] = Vec.new()
    argv.push(sdk_abs(root, helper))
    argv.push(sdk_owned_text(url))
    argv.push(sdk_abs(root, output_path))
    let result = ctx.process_runner().run_capture(argv, sdk_abs(root, sdk_join(scratch, label ++ ".fetch.stdout")), sdk_abs(root, sdk_join(scratch, label ++ ".fetch.stderr")), timeout_ms)
    if result.rc != 0:
        return sdk_fail(ctx, f"HTTPS fetch helper failed with exit code {result.rc}: " ++ result.stdout ++ result.stderr)
    0

fn sdk_gunzip(ctx: &ActionCtx, scratch: &str, archive_path: &str, tar_path: &str) -> i32:
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

fn sdk_jobs_arg(jobs: &str) -> Vec[str]:
    let out: Vec[str] = Vec.new()
    out.push("--parallel")
    if jobs.len() > 0:
        out.push(jobs)
    out

fn sdk_append_jobs(args: Vec[str], jobs: &str) -> Vec[str]:
    args.push("--parallel")
    if jobs.len() > 0:
        args.push(sdk_owned_text(jobs))
    args

fn sdk_run_capture(ctx: &ActionCtx, label: &str, argv: Vec[str], timeout_ms: i32) -> i32:
    let root = ctx.project_info().project_root()
    let command_dir = sdk_join("out/command", ctx.target_name())
    let _mkdir = ctx.fs().mkdir_all(command_dir)
    let result = ctx.process_runner().run_capture(argv, sdk_abs(root, sdk_join(command_dir, label ++ ".stdout")), sdk_abs(root, sdk_join(command_dir, label ++ ".stderr")), timeout_ms)
    if result.rc != 0:
        return sdk_fail(ctx, label ++ f" failed with exit code {result.rc}: " ++ result.stdout ++ result.stderr)
    0

fn sdk_validate_staged_paths(ctx: &ActionCtx, bootstrap_prefix: &str, output_prefix: &str) -> i32:
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
    configure.push(sdk_owned_text(cmake))
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
    build = sdk_append_jobs(move build, jobs)
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
    let windows_mt = if args.len() > 5: sdk_owned_text(args.get(5)) else: ""
    var rc = sdk_validate_staged_paths(ctx, bootstrap_prefix, output_prefix)
    if rc != 0:
        return rc
    let fs = ctx.fs()
    if not fs.exists(sdk_tool(output_prefix, "ninja")):
        return sdk_fail(ctx, "missing staged Ninja: " ++ sdk_tool(output_prefix, "ninja"))
    // Windows: cmake's own build is an MSVC-style build — clang-cl, lld-link
    // and mt.exe, as tools/build-cmake.ps1 (the recipe behind the shipped
    // cmake.exe) does. The GNU-style clang driver made CMake generate its
    // own manifest .res beside cmake's manifest .rc: `duplicate resource:
    // type MANIFEST` at cmcldeps.exe on both Windows lanes.
    if os() == "Windows":
        if not fs.exists(sdk_tool(bootstrap_prefix, "clang-cl")):
            return sdk_fail(ctx, "missing bootstrap SDK clang-cl: " ++ sdk_tool(bootstrap_prefix, "clang-cl"))
        if not fs.exists(sdk_tool(bootstrap_prefix, "lld-link")):
            return sdk_fail(ctx, "missing bootstrap SDK lld-link: " ++ sdk_tool(bootstrap_prefix, "lld-link"))
        if windows_mt.len() == 0:
            return sdk_fail(ctx, "SDK_WINDOWS_MT must name the Windows SDK mt.exe path for the Windows cmake build")
    if fs.mkdir_all(build_dir) != 0:
        return sdk_fail(ctx, "could not create CMake build directory: " ++ build_dir)
    let root = ctx.project_info().project_root()
    let cmake = sdk_abs(root, sdk_tool(bootstrap_prefix, "cmake"))
    let cc = if os() == "Windows": "clang-cl" else: "clang"
    let cxx = if os() == "Windows": "clang-cl" else: "clang++"
    let configure: Vec[str] = Vec.new()
    configure.push(sdk_owned_text(cmake))
    configure.push("-G")
    configure.push("Ninja")
    configure.push("-S")
    configure.push(sdk_abs(root, source_dir))
    configure.push("-B")
    configure.push(sdk_abs(root, build_dir))
    configure.push("-DCMAKE_BUILD_TYPE=Release")
    configure.push("-DCMAKE_INSTALL_PREFIX=" ++ sdk_abs(root, output_prefix))
    configure.push("-DCMAKE_C_COMPILER=" ++ sdk_abs(root, sdk_tool(bootstrap_prefix, cc)))
    configure.push("-DCMAKE_CXX_COMPILER=" ++ sdk_abs(root, sdk_tool(bootstrap_prefix, cxx)))
    configure.push("-DCMAKE_MAKE_PROGRAM=" ++ sdk_abs(root, sdk_tool(output_prefix, "ninja")))
    configure.push("-DBUILD_TESTING=OFF")
    configure.push("-DCMAKE_USE_OPENSSL=OFF")
    if os() == "Windows":
        configure.push("-DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreaded")
        configure.push("-DCMAKE_LINKER=" ++ sdk_abs(root, sdk_tool(bootstrap_prefix, "lld-link")))
        configure.push("-DCMAKE_MT=" ++ windows_mt)
        configure.push("-DCMAKE_RC_COMPILER=" ++ sdk_windows_rc_from_mt(windows_mt))
        // CMake links its executables with `/MANIFEST:EMBED
        // /MANIFESTINPUT:cmake.version.manifest`, so the linker merges its
        // own UAC block into that manifest. lld-link writes that block
        // without an xmlns, and a lld-link built with libxml2 (the LLVM
        // Windows releases a runner bootstraps from) merges it into
        // `ms_asmv1:level` attributes Windows rejects: the built cmake.exe
        // fails to start with "side-by-side configuration is incorrect".
        // cmake.version.manifest already carries requestedExecutionLevel,
        // so the linker's block is redundant; leave it out.
        configure.push("-DCMAKE_EXE_LINKER_FLAGS=/MANIFESTUAC:NO")
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
    build = sdk_append_jobs(move build, jobs)
    rc = sdk_run_capture(ctx, "cmake-build", build, 3600000)
    if rc != 0: return rc
    if not fs.exists(sdk_tool(output_prefix, "cmake")):
        return sdk_fail(ctx, "CMake did not install to " ++ sdk_tool(output_prefix, "cmake"))
    0

fn sdk_llvm_targets_arg(ctx: &ActionCtx, requested: &str) -> str:
    if requested.len() > 0:
        return sdk_owned_text(requested)
    // WebAssembly is in the default set: the wasm32 target (docs/wasm-target.md)
    // needs the backend and wasm-ld in every SDK the compiler links against.
    "AArch64;X86;WebAssembly"

fn sdk_targets_include_wasm(targets: &str) -> bool:
    let parts = targets.split(";")
    for i in 0..parts.len() as i32:
        let target = parts[i].trim()
        if target == "WebAssembly" or target == "all":
            return true
    false

// Run on every host: packaging decisions for another platform must not
// accidentally depend on the OS executing this test.
pub fn run_sdk_contract_tests_action(ctx: ActionCtx) -> i32:
    assert(sdk_str_compare("a", "z") < 0)
    assert(sdk_str_compare("z", "a") > 0)
    assert(sdk_str_compare("same", "same") == 0)
    assert(sdk_cmake_data_prefix() == "share/cmake-4.2/")
    assert(sdk_targets_include_wasm("AArch64;X86;WebAssembly"))
    assert(sdk_targets_include_wasm("all"))
    assert(sdk_targets_include_wasm("AArch64;X86;WebAssembly\r"))
    assert(not sdk_targets_include_wasm("AArch64;X86"))
    assert(not sdk_targets_include_wasm("NotWebAssembly"))
    let platforms: Vec[str] = Vec.new()
    platforms.push("darwin-aarch64")
    platforms.push("linux-x86_64")
    platforms.push("linux-aarch64")
    platforms.push("windows-x86_64")
    platforms.push("windows-aarch64")
    for i in 0..platforms.len() as i32:
        let platform = platforms[i]
        assert(sdk_host_tag_for_platform(platform) != "unsupported")
        if sdk_platform_is_windows(platform):
            assert(sdk_package_tool_selected("bin/wasm-ld.exe", platform))
            assert(sdk_package_tool_selected("bin/lld-link.exe", platform))
            assert(not sdk_package_tool_selected("bin/lld", platform))
        else:
            assert(sdk_package_tool_selected("bin/lld", platform))
            assert(sdk_is_unix_lld_alias("bin/wasm-ld"))
            assert(not sdk_package_tool_selected("bin/wasm-ld.exe", platform))
            // The driver the `clang` links point to ships with them.
            assert(sdk_clang_driver_rel() == "bin/clang-22")
            assert(sdk_package_tool_selected("bin/clang-22", platform))
            assert(not sdk_package_tool_selected("bin/clang-21", platform))
        let bootstrap = sdk_bootstrap_set(platform)
        for bi in 0..bootstrap.len() as i32:
            let item = bootstrap[bi]
            if item.starts_with("bin/"):
                assert(sdk_package_tool_selected(item, platform))
            else:
                assert(item.starts_with(sdk_cmake_data_prefix()))
    assert(sdk_host_tag_for_platform("windows-aarch64") == "windows-aarch64-msvc")
    // Cross the input-buffer boundary and include every byte value, an
    // empty file, executable mode, USTAR prefix paths for CMake modules,
    // and (on Unix) a relative linker alias.
    let fs = ctx.fs()
    let dir = "out/test-graph/sdk-contract-tests"
    assert(fs.mkdir_all(dir) == 0)
    let bytes: Vec[u8] = Vec.new()
    for i in 0..131073: bytes.push((i % 256) as u8)
    assert(fs.write_binary(dir ++ "/payload.bin", bytes) == 0)
    assert(fs.write_text(dir ++ "/empty", "") == 0)
    let entries: Vec[ArchiveEntry] = Vec.new()
    entries.push(archive_dir_entry("sample", 0o755))
    entries.push(archive_file_entry(dir ++ "/payload.bin", "sample/payload.bin", 0o755))
    entries.push(archive_file_entry(dir ++ "/empty", "sample/empty", 0o644))
    var long_dir = "sample/"
    for i in 0..96: long_dir = long_dir ++ "x"
    entries.push(archive_dir_entry(sdk_owned_text(long_dir), 0o755))
    entries.push(archive_file_entry(dir ++ "/payload.bin", long_dir ++ "/payload.bin", 0o644))
    if os() != "Windows":
        entries.push(archive_symlink_entry("payload.bin", "sample/alias", 0o777))
    assert(fs.write_tar_gz(dir ++ "/stream.tar.gz", entries) == 0)
    assert(fs.write_tar_gz(dir ++ "/repeat.tar.gz", entries) == 0)
    assert(fs.sha256_file(dir ++ "/stream.tar.gz") == fs.sha256_file(dir ++ "/repeat.tar.gz"))
    assert(fs.write_tar(dir ++ "/sample.tar", entries) == 0)
    let unpacked = dir ++ "/unpacked"
    if fs.exists(unpacked): assert(fs.remove_tree(unpacked) == 0)
    assert(fs.extract_tar(dir ++ "/sample.tar", unpacked) == 0)
    assert(fs.sha256_file(dir ++ "/payload.bin") == fs.sha256_file(unpacked ++ "/sample/payload.bin"))
    assert(fs.read_text(unpacked ++ "/sample/empty") == "")
    assert(fs.sha256_file(dir ++ "/payload.bin") == fs.sha256_file(unpacked ++ "/" ++ long_dir ++ "/payload.bin"))
    if os() != "Windows":
        assert(fs.sha256_file(dir ++ "/payload.bin") == fs.sha256_file(unpacked ++ "/sample/alias"))
    sdk_write_text(ctx, ctx.output(), "SDK packaging rules: all five platforms passed\n")

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
    if not sdk_targets_include_wasm(targets):
        return sdk_fail(ctx, "LLVM_TARGETS_TO_BUILD must include WebAssembly for the With SDK")
    let sdkroot = args.get(6)
    let deployment_target = if args.get(7).len() > 0: sdk_owned_text(args.get(7)) else: "11.0"
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
    configure.push(sdk_owned_text(cmake))
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
        if arch() == "x86_64":
            configure.push("-DCMAKE_ASM_MASM_COMPILER=" ++ sdk_abs(root, sdk_tool(bootstrap_prefix, "llvm-ml64")))
        configure.push("-DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreaded")
        configure.push("-DLLVM_ENABLE_PIC=OFF")
        configure.push("-DLLVM_ENABLE_DIA_SDK=OFF")
        if windows_mt.len() == 0:
            return sdk_fail(ctx, "SDK_WINDOWS_MT must name the Windows SDK mt.exe path for Windows SDK rebuilds")
        configure.push("-DCMAKE_MT=" ++ windows_mt)
        configure.push("-DCMAKE_RC_COMPILER=" ++ sdk_windows_rc_from_mt(windows_mt))
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
            if comp_arch_is_aarch64(arch()):
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
    build = sdk_append_jobs(move build, jobs)
    rc = sdk_run_capture(ctx, "llvm-build", build, 21600000)
    if rc != 0: return rc
    let libclang = if os() == "Windows": sdk_join(output_prefix, "lib/libclang.lib") else: sdk_join(output_prefix, "lib/libclang.a")
    if not fs.exists(libclang):
        return sdk_fail(ctx, "static libclang archive was not installed: " ++ libclang)
    if not fs.exists(sdk_tool(output_prefix, "clang")):
        return sdk_fail(ctx, "clang driver was not installed: " ++ sdk_tool(output_prefix, "clang"))
    if not fs.exists(sdk_tool(output_prefix, "llvm-nm")):
        return sdk_fail(ctx, "llvm-nm was not installed: " ++ sdk_tool(output_prefix, "llvm-nm"))
    rc = sdk_validate_wasm_install(ctx, output_prefix)
    if rc != 0: return rc
    sdk_archive_clang_main(ctx, root, sdk_abs(root, build_dir) ++ "/tools/clang/tools/driver/CMakeFiles/clang.dir", output_prefix)

// `with cc` is clang's driver linked into the compiler (src/compiler/
// ClangDriver.w). LLVM installs that driver only as the bin/clang executable;
// its objects — driver, cc1, cc1as, cc1gen_reproducer, where clang_main lives —
// stay in the build tree. Archive them next to the other clang libraries, where
// the compiler link already picks up every libclang*.a / clang*.lib.
fn sdk_clang_main_archive(prefix: &str) -> str:
    sdk_join(prefix, if os() == "Windows": "lib/clangMain.lib" else: "lib/libclangMain.a")

fn sdk_archive_clang_main(ctx: &ActionCtx, root: &str, objects_dir: &str, output_prefix: &str) -> i32:
    let ext = if os() == "Windows": ".cpp.obj" else: ".cpp.o"
    let archive = sdk_abs(root, sdk_clang_main_archive(output_prefix))
    var argv: Vec[str] = Vec.new()
    if os() == "Windows":
        argv.push(sdk_abs(root, sdk_tool(output_prefix, "llvm-lib")))
        argv.push("/OUT:" ++ archive)
    else:
        argv.push(sdk_abs(root, sdk_tool(output_prefix, "llvm-ar")))
        argv.push("rcs")
        argv.push(archive)
    // Pushed one by one: the build layer runs on the pinned seed (#1122).
    let names: Vec[str] = Vec.new()
    names.push("driver")
    names.push("cc1_main")
    names.push("cc1as_main")
    names.push("cc1gen_reproducer_main")
    for i in 0..names.len() as i32:
        let object = objects_dir ++ "/" ++ names[i] ++ ext
        if not ctx.fs().host_exists(object):
            return sdk_fail(ctx, "clang driver object was not built: " ++ object)
        argv.push(object)
    let rc = sdk_run_capture(ctx, "clang-main-archive", argv, 120000)
    if rc != 0: return rc
    if not ctx.fs().host_exists(sdk_abs(root, sdk_clang_main_archive(output_prefix))):
        return sdk_fail(ctx, "clang driver archive was not written: " ++ sdk_clang_main_archive(output_prefix))
    0

// A packaged SDK (`with build :deps`) predating `with cc` has no clang driver
// archive, and rebuilding LLVM for it is hours per platform. The driver is
// four small files that need only the SDK's installed headers: fetch them from
// the LLVM release tag, check them against pinned digests, and compile them
// with the SDK's own clang++.
fn sdk_clang_main_source_sha256(name: &str) -> str:
    if name == "driver": return "3363bf2ecfd09487855a53551d87589daad81b43a749cb18859610f72f47cedf"
    if name == "cc1_main": return "7705c2a5e60d067e9858bb9f72ede2b6012ede6c020b13cc7871a894246ec50f"
    if name == "cc1as_main": return "41ab8f70668e50cd58977c4072eb3cd73fdace21603207fc26c2ea8d33cb997c"
    if name == "cc1gen_reproducer_main": return "c196cd251ca3ddc3323c2bc2bedd2389f7672ddaa3c1c90b8f2a414bc515d4fe"
    ""

pub fn run_sdk_clang_main_action(ctx: ActionCtx) -> i32:
    let rc = sdk_ensure_clang_main(ctx)
    if rc != 0: return rc
    // The marker says which it is; the generated clang resource module reads
    // the same fact and takes this file as an input, so it is regenerated
    // when an SDK gains the archive.
    let root = ctx.project_info().project_root()
    let linked = ctx.fs().host_exists(sdk_abs(root, sdk_clang_main_archive(comp_llvm_prefix_for_root(root))))
    if ctx.fs().mkdir_all(sdk_dirname(ctx.output())) != 0 or ctx.fs().write_text(ctx.output(), (if linked: "linked" else: "absent") ++ "\n") != 0:
        return sdk_fail(ctx, "could not write " ++ ctx.output())
    0

fn sdk_ensure_clang_main(ctx: &ActionCtx) -> i32:
    let fs = ctx.fs()
    let root = ctx.project_info().project_root()
    // The same SDK the link will read, which on CI is LLVM_PREFIX, not .deps.
    let prefix = comp_llvm_prefix_for_root(root)
    if fs.host_exists(sdk_abs(root, sdk_clang_main_archive(prefix))):
        return 0
    // Compiling the driver needs LLVM's and clang's headers. A packaged SDK
    // ships libraries and tools only; it has to be published with the archive.
    if not fs.host_exists(sdk_abs(root, sdk_join(prefix, "include/clang/Driver/Driver.h"))):
        print("note: the LLVM SDK at " ++ prefix ++ " predates `with cc` (no clang driver archive, and no headers to build one): this compiler will have no C compiler until that SDK is republished")
        return 0
    if not fs.host_exists(sdk_abs(root, sdk_tool(prefix, "clang++"))):
        return sdk_fail(ctx, "no clang++ in the LLVM SDK at " ++ prefix)
    let scratch = "out/tmp/sdk-clang-main"
    if fs.mkdir_all(scratch) != 0:
        return sdk_fail(ctx, "could not create " ++ scratch)
    let ext = if os() == "Windows": ".cpp.obj" else: ".cpp.o"
    let names: Vec[str] = Vec.new()
    names.push("driver")
    names.push("cc1_main")
    names.push("cc1as_main")
    names.push("cc1gen_reproducer_main")
    for i in 0..names.len() as i32:
        let source = sdk_join(scratch, names[i] ++ ".cpp")
        let url = "https://raw.githubusercontent.com/llvm/llvm-project/llvmorg-" ++ COMPILER_LLVM_VERSION ++ "/clang/tools/driver/" ++ names[i] ++ ".cpp"
        // curl, as `with get` downloads: the HTTPS helper is a With program the
        // pinned linux-aarch64 seed cannot link (with_vec_append_bytes). The
        // digest below is what makes the download trustworthy.
        var fetch: Vec[str] = Vec.new()
        fetch.push("curl")
        fetch.push("-fsSL")
        fetch.push("--retry")
        fetch.push("3")
        fetch.push("-o")
        fetch.push(sdk_abs(root, source))
        fetch.push(sdk_owned_text(url))
        var rc = sdk_run_capture(ctx, "clang-main-fetch-" ++ names[i], fetch, 120000)
        if rc != 0: return rc
        let digest = fs.sha256_file(source)
        if digest != sdk_clang_main_source_sha256(names[i]):
            return sdk_fail(ctx, url ++ " has sha256 " ++ digest ++ ", expected " ++ sdk_clang_main_source_sha256(names[i]))
        var argv: Vec[str] = Vec.new()
        argv.push(sdk_abs(root, sdk_tool(prefix, "clang++")))
        argv.push("-c")
        argv.push(sdk_abs(root, source))
        argv.push("-o")
        argv.push(sdk_abs(root, sdk_join(scratch, names[i] ++ ext)))
        argv.push("-O2")
        argv.push("-std=c++17")
        argv.push("-fno-rtti")
        argv.push("-fno-exceptions")
        argv.push("-I" ++ sdk_abs(root, sdk_join(prefix, "include")))
        argv.push("-D__STDC_CONSTANT_MACROS")
        argv.push("-D__STDC_FORMAT_MACROS")
        argv.push("-D__STDC_LIMIT_MACROS")
        if os() == "Windows":
            argv.push("-D_CRT_SECURE_NO_WARNINGS")
        else:
            argv.push("-fPIC")
            argv.push("-D_GNU_SOURCE")
        if os() == "Macos":
            let sdkroot = comp_host_sdk_path(ctx)
            if sdkroot.len() > 0:
                argv.push("-isysroot")
                argv.push(sdkroot)
        rc = sdk_run_capture(ctx, "clang-main-" ++ names[i], argv, 600000)
        if rc != 0: return rc
    sdk_archive_clang_main(ctx, root, sdk_abs(root, scratch), prefix)
