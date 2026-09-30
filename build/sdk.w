module build.sdk

use std.build
use std.string.StringBuilder
use std.sysinfo
use build.compiler
use build.par
use std.io.print_str
fn sdk_owned_text(s: &str): s ++ ""

const SDK_NINJA_VERSION: str = "1.13.1"
const SDK_NINJA_SHA256: str = "f0055ad0369bf2e372955ba55128d000cfcc21777057806015b45e4accbebf23"
const SDK_CMAKE_VERSION: str = "4.2.3"
const SDK_CMAKE_SHA256: str = "7efaccde8c5a6b2968bad6ce0fe60e19b6e10701a12fce948c2bf79bac8a11e9"
const SDK_LLVM_TAG_TAR_GZ_SHA256: str = "ba534c6835a5b9c2162c806e269799fe41fca952a3c25baff1afcff23841ec2b"

fn sdk_fail(ctx: &ActionCtx, message: &str) -> i32:
    ctx.diagnostics().error(ctx.target_name() ++ ": " ++ message)

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

pub fn sdk_platform_is_windows(platform: &str) -> bool:
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
        // #1915: the Windows SDK's LLVM is built for <arch>-w64-windows-gnu
        // against the SDK's own libc++, never by clang-cl against Visual
        // Studio's STL (whose runtime every compiler link would then need).
        let cxx_target = sdk_cache_line(cache, "CMAKE_CXX_COMPILER_TARGET:")
        if cc.contains("clang-cl") or cxx.contains("clang-cl") or not cxx.contains("clang++") or not cxx_target.contains("windows-gnu"):
            return sdk_fail(ctx, "refusing to package a Windows SDK whose LLVM is not built by clang++ for windows-gnu against the SDK's libc++; CMAKE_CXX_COMPILER=" ++ cxx ++ " " ++ cxx_target)
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
        rc = sdk_check_file(ctx, sdk_join(prefix, "lib/libclang.a"), "static libclang archive")
        if rc != 0: return rc
        // What a Windows link and the next SDK build read (#1915): the libc,
        // the C++ runtime, compiler-rt's builtins, and the tools the build
        // runs by name.
        let arch_name = if platform == "windows-aarch64": "aarch64" else: "x86_64"
        rc = sdk_check_file(ctx, sdk_windows_libc_marker(prefix, arch_name), "Windows C runtime startup (libc/windows)")
        if rc != 0: return rc
        rc = sdk_check_file(ctx, sdk_windows_libc_lib_dir(prefix, arch_name) ++ "/libc++.a", "libc++")
        if rc != 0: return rc
        rc = sdk_check_file(ctx, sdk_compiler_rt_builtins(prefix, arch_name), "compiler-rt builtins")
        if rc != 0: return rc
        let tools: Vec[str] = Vec.new()
        tools.push("clang")
        tools.push("clang++")
        tools.push("cmake")
        tools.push("ninja")
        tools.push("lld-link")
        tools.push("ld.lld")
        tools.push("llvm-ar")
        tools.push("llvm-lib")
        tools.push("llvm-ranlib")
        tools.push("llvm-dlltool")
        tools.push("llvm-rc")
        tools.push("llvm-windres")
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
        // stage2-debug-lines (:fixpoint) reads ELF and Mach-O line tables
        // with llvm-dwarfdump; on PE it uses llvm-readobj.
        tools.push("llvm-dwarfdump")
        // nightly-release.yml's SDK contract checks these too (its
        // `for tool in ...` list); a package without them fails that job.
        tools.push("llvm-ar")
        tools.push("llvm-config")
        tools.push("llvm-objcopy")
        tools.push("llvm-ranlib")
        tools.push("llvm-nm")
        tools.push("llvm-readobj")
        tools.push("llvm-strip")
        for i in 0..tools.len() as i32:
            rc = sdk_check_file(ctx, sdk_required_tool(prefix, tools[i]), tools[i])
            if rc != 0: return rc
    rc = sdk_check_file(ctx, sdk_clang_main_archive(ctx.fs(), prefix), "clang driver archive (with cc)")
    if rc != 0: return rc
    if platform == "darwin-aarch64":
        rc = sdk_check_file(ctx, sdk_dsymutil_main_archive(prefix), "dsymutil archive (with __dsymutil, #1915)")
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
    let linker_archive = "lib/liblldWasm.a"
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
        let archive = "lib" ++ name ++ ".a"
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
    if sdk_platform_is_windows(platform) and fs.is_dir(sdk_join(prefix, "libc")):
        let libc = fs.list_files(sdk_join(prefix, "libc"))
        for i in 0..libc.len() as i32:
            candidates.push(sdk_owned_text(libc[i]))
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
            // Static archives, GNU-named on every platform: the Windows SDK's
            // LLVM is a windows-gnu build (#1915).
            let lib_rel = rel.slice(4, rel.len())
            if not sdk_has_slash(lib_rel) and rel.ends_with(".a"):
                selected.push(sdk_owned_text(path))
        else if rel.starts_with("libc/") and sdk_platform_is_windows(platform):
            // The Windows C runtime and C++ runtime (#1915), whole.
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
        // #1915: the names the GNU-driver build of the next SDK, and the
        // libc step, run the multicall binaries under.
        tools.push("bin/ld.lld.exe")
        tools.push("bin/wasm-ld.exe")
        tools.push("bin/llvm-lib.exe")
        tools.push("bin/llvm-ar.exe")
        tools.push("bin/llvm-ranlib.exe")
        tools.push("bin/llvm-dlltool.exe")
        tools.push("bin/llvm-rc.exe")
        tools.push("bin/llvm-windres.exe")
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
        tools.push("bin/llvm-dwarfdump")
        tools.push("bin/llvm-ar")
        tools.push("bin/llvm-config")
        tools.push("bin/llvm-objcopy")
        tools.push("bin/llvm-ranlib")
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
// its links, CMake with its module tree, and Ninja; on Windows (#1915) the
// linker and archiver under the names the GNU driver and CMake run them by.
fn sdk_bootstrap_set(platform: &str) -> Vec[str]:
    let set: Vec[str] = Vec.new()
    if sdk_platform_is_windows(platform):
        set.push("bin/clang.exe")
        set.push("bin/clang++.exe")
        set.push("bin/lld-link.exe")
        set.push("bin/ld.lld.exe")
        set.push("bin/llvm-ar.exe")
        set.push("bin/llvm-ranlib.exe")
        set.push("bin/cmake.exe")
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
    // #1915: the darwin SDK carries the darwin sysroot, as its sysroot/.
    let sysroot_files = if platform == "darwin-aarch64": sdk_merge_sort_strings(fs.list_files(sdk_darwin_sysroot_dir())) else: Vec.new()
    for i in 0..sysroot_files.len() as i32:
        dirs = sdk_add_parent_dirs(move dirs, sdk_base, "sysroot/" ++ sdk_rel_path(sdk_darwin_sysroot_dir(), sysroot_files[i]))
    dirs = sdk_sort_strings(dirs)
    let entries: Vec[ArchiveEntry] = Vec.new()
    for i in 0..dirs.len() as i32:
        entries.push(archive_dir_entry(sdk_owned_text(dirs[i]), 0o755))
    for i in 0..files.len() as i32:
        let path = files[i]
        let rel = sdk_rel_path(prefix, path)
        entries.push(archive_file_entry(sdk_owned_text(path), sdk_base ++ "/" ++ rel, sdk_file_mode(rel)))
    for i in 0..sysroot_files.len() as i32:
        let rel = "sysroot/" ++ sdk_rel_path(sdk_darwin_sysroot_dir(), sysroot_files[i])
        entries.push(archive_file_entry(sdk_owned_text(sysroot_files[i]), sdk_base ++ "/" ++ rel, 0o644))
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
    let clang = "lib/libclang.a"
    let lld = if sdk_platform_is_windows(platform): "bin/lld-link.exe" else: "bin/lld"
    let wasm = if sdk_platform_is_windows(platform): "bin/wasm-ld.exe" else: "bin/wasm-ld"
    if not selected.contains(sdk_base ++ "/" ++ clang ++ "\n") or not selected.contains(sdk_base ++ "/" ++ lld ++ "\n") or not selected.contains(sdk_base ++ "/" ++ wasm ++ "\n"):
        return sdk_fail(ctx, "SDK archive selection omitted required libraries or linkers")
    if not selected.contains(sdk_base ++ "/" ++ sdk_cmake_data_prefix() ++ "Modules/CMake.cmake\n"):
        return sdk_fail(ctx, "SDK archive selection omitted CMake runtime modules")
    if platform == "darwin-aarch64":
        if not selected.contains(sdk_base ++ "/sysroot/usr/lib/libSystem.tbd\n") or not selected.contains(sdk_base ++ "/sysroot/usr/lib/libc++.tbd\n") or not selected.contains(sdk_base ++ "/sysroot/usr/include/stdio.h\n"):
            return sdk_fail(ctx, "the darwin SDK archive omitted its sysroot (#1915): run `with build :darwin-sysroot`")
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
        // A tree extracted before the backport existed still gets it.
        return sdk_patch_llvm_source(ctx, source_dir)
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
    rc = sdk_patch_llvm_source(ctx, source_dir)
    if rc != 0:
        return rc
    sdk_write_text(ctx, marker, "ok\n")

// #1826: the backport of llvm/llvm-project b8007a8e ("[ld64.lld, llvm-otool]
// Minimal arm64e.x1 support", main 2026-09-11; no release carries it). Xcode
// 27's SDK lists the arm64e.x1 slice (CPU_SUBTYPE_ARM64E_X1 = 12) in every
// .tbd stub, and TextAPI rejects a stub whose target it cannot parse, so our
// ld64.lld could not read libSystem at all. The two lines lld needs are
// inserted after their exact anchors; a missing anchor is a failure, never a
// skipped patch. The patch is pinned to 22.1.6: a version bump must delete
// it (an LLVM that carries the commit has the line already, and this step
// refuses to guess at any other tree).
const SDK_LLVM_PATCH_VERSION: str = "22.1.6"

fn sdk_patch_llvm_source(ctx: &ActionCtx, source_dir: &str) -> i32:
    if sdk_basename(source_dir) != "llvm-project-llvmorg-" ++ compiler_llvm_version():
        return 0
    if compiler_llvm_version() != SDK_LLVM_PATCH_VERSION:
        return sdk_fail(ctx, "the arm64e.x1 backport (#1826) is written for LLVM " ++ SDK_LLVM_PATCH_VERSION ++ ", not " ++ compiler_llvm_version() ++ ": delete sdk_patch_llvm_source if the new LLVM carries llvm/llvm-project b8007a8e, or re-anchor it")
    var rc = sdk_insert_line_after(ctx, sdk_join(source_dir, "llvm/include/llvm/TextAPI/Architecture.def"),
        "ARCHINFO(arm64e, arm64e, MachO::CPU_TYPE_ARM64, MachO::CPU_SUBTYPE_ARM64E, 64)",
        "ARCHINFO(arm64e_x1, arm64e.x1, MachO::CPU_TYPE_ARM64, MachO::CPU_SUBTYPE_ARM64E_X1, 64)")
    if rc != 0: return rc
    rc = sdk_insert_line_after(ctx, sdk_join(source_dir, "llvm/include/llvm/BinaryFormat/MachO.h"),
        "  CPU_SUBTYPE_ARM64E = 2,",
        "  CPU_SUBTYPE_ARM64E_X1 = 12,")
    if rc != 0: return rc
    sdk_patch_dsymutil_cfbundle(ctx, source_dir)

// #1915: dsymutil is linked into the compiler (`with __dsymutil`), and the
// compiler links no Apple framework. dsymutil's CFBundle.cpp reads an app
// bundle's Info.plist through CoreFoundation, under `#ifdef __APPLE__`; its
// three guards become `#if 0`, so dsymutil takes the path it takes on every
// other host (no bundle version strings in a dSYM's Info.plist, which a
// plain executable has none of). Exactly three guards, or the patch refuses.
const SDK_DSYMUTIL_CFBUNDLE_GUARD: str = "#if 0 // With (#1915): no CoreFoundation in the compiler"

fn sdk_patch_dsymutil_cfbundle(ctx: &ActionCtx, source_dir: &str) -> i32:
    let path = sdk_join(source_dir, "llvm/tools/dsymutil/CFBundle.cpp")
    let fs = ctx.fs()
    let text = fs.read_text(path)
    if text.len() == 0:
        return sdk_fail(ctx, "dsymutil CoreFoundation patch (#1915): could not read " ++ path)
    var out = StringBuilder.with_capacity(text.len() + 256)
    var guards = 0
    var patched = 0
    let pieces = text.split("\n")
    for i in 0..pieces.len() as i32:
        if i > 0:
            out.push_str("\n")
        if pieces[i] == "#ifdef __APPLE__":
            guards = guards + 1
            out.push_str(SDK_DSYMUTIL_CFBUNDLE_GUARD)
        else:
            if pieces[i] == SDK_DSYMUTIL_CFBUNDLE_GUARD:
                patched = patched + 1
            out.push_str(pieces[i])
    if guards == 0 and patched == 3:
        return 0
    if guards != 3 or patched != 0:
        return sdk_fail(ctx, "dsymutil CoreFoundation patch (#1915): expected three `#ifdef __APPLE__` lines in " ++ path ++ f", found {guards} (and {patched} patched): re-anchor it for this LLVM")
    if fs.write_text(path, out.to_str()) != 0:
        return sdk_fail(ctx, "dsymutil CoreFoundation patch (#1915): could not write " ++ path)
    0

// Insert `line` after the one line equal to `anchor`; already present is ok.
fn sdk_insert_line_after(ctx: &ActionCtx, path: &str, anchor: &str, line: &str) -> i32:
    let fs = ctx.fs()
    let text = fs.read_text(path)
    if text.len() == 0:
        return sdk_fail(ctx, "arm64e.x1 backport (#1826): could not read " ++ path)
    var out = StringBuilder.with_capacity(text.len() + line.len() + 1)
    var anchors = 0
    let pieces = text.split("\n")
    // "a\nb\n" splits to [a, b, ""]: a separator between every two pieces
    // rebuilds the text byte for byte.
    for i in 0..pieces.len() as i32:
        let current = pieces[i]
        if current == line:
            return 0
        if i > 0:
            out.push_str("\n")
        out.push_str(current)
        if current == anchor:
            anchors = anchors + 1
            out.push_str("\n")
            out.push_str(line)
    if anchors != 1:
        return sdk_fail(ctx, "arm64e.x1 backport (#1826): expected exactly one anchor line in " ++ path ++ f", found {anchors}: `" ++ anchor ++ "`")
    if fs.write_text(path, out.to_str()) != 0:
        return sdk_fail(ctx, "arm64e.x1 backport (#1826): could not write " ++ path)

    0

fn sdk_jobs_arg(jobs: &str) -> Vec[str]:
    var out: Vec[str] = Vec.new()
    out.push("--parallel")
    if jobs.len() > 0:
        out.push(jobs.clone())
    out

fn sdk_append_jobs(args: Vec[str], jobs: &str) -> Vec[str]:
    args.push("--parallel")
    if jobs.len() > 0:
        args.push(sdk_owned_text(jobs))
    args

// The toolchain-flag variables a shell may carry (LDFLAGS=-L/opt/llvm-x/lib,
// CPPFLAGS=-I…, from a package manager's LLVM). CMake folds them into every
// compile and link line, so a system LLVM's libc++ was linked into the SDK's
// ninja ahead of the sysroot's (2026-09-28). The SDK is built by the tools
// the graph names and nothing else: every SDK subprocess sees these empty.
fn sdk_scrubbed_env_names() -> Vec[str]:
    // Pushed one by one: the build layer runs on the pinned seed (#1122).
    var names: Vec[str] = Vec.new()
    names.push("CPPFLAGS")
    names.push("CFLAGS")
    names.push("CXXFLAGS")
    names.push("LDFLAGS")
    names.push("CPATH")
    names.push("C_INCLUDE_PATH")
    names.push("CPLUS_INCLUDE_PATH")
    names.push("LIBRARY_PATH")
    names.push("CMAKE_PREFIX_PATH")
    names.push("CMAKE_LIBRARY_PATH")
    names.push("CMAKE_INCLUDE_PATH")
    names

fn sdk_run_capture(ctx: &ActionCtx, label: &str, argv: Vec[str], timeout_ms: i32) -> i32:
    let root = ctx.project_info().project_root()
    let command_dir = sdk_join("out/command", ctx.target_name())
    let _mkdir = ctx.fs().mkdir_all(command_dir)
    if argv.len() == 0:
        return sdk_fail(ctx, label ++ ": empty command")
    var spec = process_spec(argv.get(0).clone()).timeout(timeout_ms)
    for i in 1..argv.len() as i32:
        spec = (move spec).arg(argv[i].clone())
    for name in sdk_scrubbed_env_names():
        spec = (move spec).env_var(name.clone(), "")
    let result = ctx.process_runner().run_spec(move spec, sdk_abs(root, sdk_join(command_dir, label ++ ".stdout")), sdk_abs(root, sdk_join(command_dir, label ++ ".stderr")))
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
    if os() == "Windows":
        // #1915: a windows-gnu program against the output SDK's libc and
        // libc++, like everything in it; the bootstrap's ninja.exe (a
        // Visual Studio /MD build) needs msvcp140/vcruntime140 to run.
        let gnu = sdk_windows_gnu_cmake_args(&ctx, bootstrap_prefix, output_prefix, sdk_windows_host_arch(), sdk_join(build_dir, "tools"))
        if not gnu.ok: return 1
        for i in 0..gnu.items.len() as i32:
            configure.push(sdk_owned_text(gnu.items[i]))
    else:
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
    var rc = sdk_validate_staged_paths(ctx, bootstrap_prefix, output_prefix)
    if rc != 0:
        return rc
    let fs = ctx.fs()
    if not fs.exists(sdk_tool(output_prefix, "ninja")):
        return sdk_fail(ctx, "missing staged Ninja: " ++ sdk_tool(output_prefix, "ninja"))
    // Windows (#1915): cmake is a windows-gnu program against the output
    // SDK's libc and libc++, like the rest of the SDK; its version and
    // manifest resources (cmake.version.manifest.rc, CMakeVersion.rc) go
    // through the output SDK's own llvm-windres, which the LLVM build
    // installs before this runs. No Visual Studio, mt.exe or rc.exe.
    if os() == "Windows" and not fs.exists(sdk_tool(output_prefix, "llvm-windres")):
        return sdk_fail(ctx, "missing staged llvm-windres (the SDK's LLVM builds it; run :sdk-llvm first): " ++ sdk_tool(output_prefix, "llvm-windres"))
    if fs.mkdir_all(build_dir) != 0:
        return sdk_fail(ctx, "could not create CMake build directory: " ++ build_dir)
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
    configure.push("-DCMAKE_INSTALL_PREFIX=" ++ sdk_abs(root, output_prefix))
    if os() == "Windows":
        let gnu = sdk_windows_gnu_cmake_args(&ctx, bootstrap_prefix, output_prefix, sdk_windows_host_arch(), sdk_join(build_dir, "tools"))
        if not gnu.ok: return 1
        for i in 0..gnu.items.len() as i32:
            configure.push(sdk_owned_text(gnu.items[i]))
        configure.push("-DCMAKE_RC_COMPILER=" ++ sdk_abs(root, sdk_tool(output_prefix, "llvm-windres")))
        // llvm-windres preprocesses with clang and no sysroot: the .rc files
        // include <winuser.h> from the SDK's libc headers.
        configure.push("-DCMAKE_RC_FLAGS=-I" ++ sdk_abs(root, sdk_windows_libc_root(output_prefix) ++ "/include"))
    else:
        configure.push("-DCMAKE_C_COMPILER=" ++ sdk_abs(root, sdk_tool(bootstrap_prefix, "clang")))
        configure.push("-DCMAKE_CXX_COMPILER=" ++ sdk_abs(root, sdk_tool(bootstrap_prefix, "clang++")))
    configure.push("-DCMAKE_MAKE_PROGRAM=" ++ sdk_abs(root, sdk_tool(output_prefix, "ninja")))
    configure.push("-DBUILD_TESTING=OFF")
    configure.push("-DCMAKE_USE_OPENSSL=OFF")
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
    // WebAssembly is in the default set: the wasm32 target (docs/proposals/wasm-target.md)
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
    if args.len() < 8:
        return sdk_fail(ctx, "requires bootstrap-prefix, output-prefix, source-dir, build-dir, jobs, targets, sdkroot, and deployment-target args")
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
    // Windows builds cmake after LLVM (its resources need the SDK's own
    // llvm-windres, #1915), so LLVM configures with the bootstrap's cmake.
    let cmake_prefix = if os() == "Windows": sdk_owned_text(bootstrap_prefix) else: sdk_owned_text(output_prefix)
    var rc = sdk_validate_staged_paths(ctx, bootstrap_prefix, output_prefix)
    if rc != 0:
        return rc
    let fs = ctx.fs()
    if not fs.exists(sdk_tool(cmake_prefix, "cmake")):
        return sdk_fail(ctx, "missing CMake: " ++ sdk_tool(cmake_prefix, "cmake"))
    if not fs.exists(sdk_tool(output_prefix, "ninja")):
        return sdk_fail(ctx, "missing staged Ninja: " ++ sdk_tool(output_prefix, "ninja"))
    if fs.mkdir_all(build_dir) != 0:
        return sdk_fail(ctx, "could not create LLVM build directory: " ++ build_dir)
    let root = ctx.project_info().project_root()
    let cmake = sdk_abs(root, sdk_tool(cmake_prefix, "cmake"))
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
        // #1915: LLVM, clang and lld are windows-gnu code against the output
        // SDK's own libc, libc++ and compiler-rt (built before this by
        // :sdk-windows-libc, :sdk-compiler-rt-builtins and :sdk-libcxx), so
        // the compiler's link needs nothing Visual Studio ships. The SDK's
        // clang defaults to that toolchain (compiler-rt, libunwind, libc++,
        // lld) for a windows-gnu target, which is what `with cc` compiles
        // for. MinGW builds use no .rc resources (AddLLVM's
        // add_windows_version_resource_file is MSVC-only), and BLAKE3's
        // assembly is its GNU .S flavor, so no rc.exe or llvm-ml64.
        let gnu = sdk_windows_gnu_cmake_args(&ctx, bootstrap_prefix, output_prefix, sdk_windows_host_arch(), sdk_join(build_dir, "tools"))
        if not gnu.ok: return 1
        for i in 0..gnu.items.len() as i32:
            configure.push(sdk_owned_text(gnu.items[i]))
        configure.push("-DLLVM_HOST_TRIPLE=" ++ sdk_windows_triple(sdk_windows_host_arch()))
        configure.push("-DCLANG_DEFAULT_RTLIB=compiler-rt")
        configure.push("-DCLANG_DEFAULT_UNWINDLIB=libunwind")
        configure.push("-DCLANG_DEFAULT_CXX_STDLIB=libc++")
        configure.push("-DCLANG_DEFAULT_LINKER=lld")
        configure.push("-DLLVM_ENABLE_PIC=OFF")
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
    let libclang = sdk_join(output_prefix, "lib/libclang.a")
    if not fs.exists(libclang):
        return sdk_fail(ctx, "static libclang archive was not installed: " ++ libclang)
    if not fs.exists(sdk_tool(output_prefix, "clang")):
        return sdk_fail(ctx, "clang driver was not installed: " ++ sdk_tool(output_prefix, "clang"))
    if not fs.exists(sdk_tool(output_prefix, "llvm-nm")):
        return sdk_fail(ctx, "llvm-nm was not installed: " ++ sdk_tool(output_prefix, "llvm-nm"))
    rc = sdk_validate_wasm_install(ctx, output_prefix)
    if rc != 0: return rc
    let clang_rc = sdk_archive_clang_main(ctx, root, sdk_abs(root, build_dir) ++ "/tools/clang/tools/driver/CMakeFiles/clang.dir", output_prefix)
    if clang_rc != 0: return clang_rc
    if os() != "Macos": return 0
    sdk_archive_dsymutil_main(ctx, root, sdk_abs(root, build_dir) ++ "/tools/dsymutil/CMakeFiles/dsymutil.dir", output_prefix)

// #1915: `with __dsymutil` is LLVM's dsymutil linked into the compiler, as
// `with cc` is clang's driver: a macOS debug build collects its DWARF into a
// .dSYM without Xcode's dsymutil. LLVM installs dsymutil only as bin/dsymutil;
// its objects (dsymutil_main in dsymutil.cpp; not the generated driver with
// main) are archived next to the other libraries. macOS only: dsymutil reads
// Mach-O debug maps.
pub fn sdk_dsymutil_main_archive(prefix: &str) -> str: sdk_join(prefix, "lib/libdsymutilMain.a")

fn sdk_archive_dsymutil_main(ctx: &ActionCtx, root: &str, objects_dir: &str, output_prefix: &str) -> i32:
    let archive = sdk_abs(root, sdk_dsymutil_main_archive(output_prefix))
    let _stale = ctx.fs().remove_file(archive)
    var argv: Vec[str] = Vec.new()
    argv.push(sdk_abs(root, sdk_tool(output_prefix, "llvm-ar")))
    argv.push("rcs")
    argv.push(archive.clone())
    // Pushed one by one: the build layer runs on the pinned seed (#1122).
    let names: Vec[str] = Vec.new()
    names.push("BinaryHolder")
    names.push("CFBundle")
    names.push("DebugMap")
    names.push("dsymutil")
    names.push("DwarfLinkerForBinary")
    names.push("MachODebugMapParser")
    names.push("MachOUtils")
    names.push("RelocationMap")
    names.push("Reproducer")
    names.push("SwiftModule")
    for i in 0..names.len() as i32:
        let object = objects_dir ++ "/" ++ names[i] ++ ".cpp.o"
        if not ctx.fs().host_exists(object):
            return sdk_fail(ctx, "dsymutil object was not built: " ++ object)
        argv.push(object)
    let rc = sdk_run_capture(ctx, "dsymutil-main-archive", argv, 120000)
    if rc != 0: return rc
    if not ctx.fs().host_exists(archive):
        return sdk_fail(ctx, "dsymutil archive was not written: " ++ sdk_dsymutil_main_archive(output_prefix))
    0

// `with cc` is clang's driver linked into the compiler (src/compiler/
// ClangDriver.w). LLVM installs that driver only as the bin/clang executable;
// its objects — driver, cc1, cc1as, cc1gen_reproducer, where clang_main lives —
// stay in the build tree. Archive them next to the other clang libraries, where
// the compiler link already picks up every libclang*.a / clang*.lib.
fn sdk_clang_main_archive(fs: &ToolFs, prefix: &str) -> str:
    // The Visual Studio-built Windows SDKs pinned before #1915 name it
    // clangMain.lib; every SDK built since names it GNU-style.
    if os() == "Windows" and fs.exists(sdk_join(prefix, "lib/clangMain.lib")):
        return sdk_join(prefix, "lib/clangMain.lib")
    sdk_join(prefix, "lib/libclangMain.a")

fn sdk_archive_clang_main(ctx: &ActionCtx, root: &str, objects_dir: &str, output_prefix: &str) -> i32:
    let ext = if os() == "Windows": ".cpp.obj" else: ".cpp.o"
    let archive = sdk_abs(root, sdk_clang_main_archive(ctx.fs(), output_prefix))
    // GNU-named and made by llvm-ar on every platform: the Windows SDK's LLVM
    // is a windows-gnu build (#1915); CMake there still names objects .obj.
    var argv: Vec[str] = Vec.new()
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
    if not ctx.fs().host_exists(sdk_abs(root, sdk_clang_main_archive(ctx.fs(), output_prefix))):
        return sdk_fail(ctx, "clang driver archive was not written: " ++ sdk_clang_main_archive(ctx.fs(), output_prefix))
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
    let linked = ctx.fs().host_exists(sdk_abs(root, sdk_clang_main_archive(ctx.fs(), comp_llvm_prefix_for_root(root))))
    if ctx.fs().mkdir_all(sdk_dirname(ctx.output())) != 0 or ctx.fs().write_text(ctx.output(), (if linked: "linked" else: "absent") ++ "\n") != 0:
        return sdk_fail(ctx, "could not write " ++ ctx.output())
    0

fn sdk_ensure_clang_main(ctx: &ActionCtx) -> i32:
    let fs = ctx.fs()
    let root = ctx.project_info().project_root()
    // The same SDK the link will read, which on CI is LLVM_PREFIX, not .deps.
    let prefix = comp_llvm_prefix_for_root(root)
    if fs.host_exists(sdk_abs(root, sdk_clang_main_archive(ctx.fs(), prefix))):
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

// ── The darwin sysroot (#1915) ─────────────────────────────────────────
//
// Linking a With program on macOS reads nothing but what ships in our SDK
// and the `with` binary: no Xcode, no Command Line Tools, no Apple SDK
// (Eric, 2026-09-29: "zero dependencies in all platforms ... except our own
// SDK and system calls"). What a link against libSystem needs, and what
// c_import of libc needs, is this sysroot:
//
//   usr/lib/libSystem.tbd    the text stub of /usr/lib/libSystem.B.dylib
//   usr/lib/lib{c,m,pthread,dl}.tbd   the same stub, as the Apple SDK aliases it
//   usr/lib/libc++.tbd       /usr/lib/libc++.1.dylib, for the compiler's own
//                            link (the LLVM archives are C++)
//   usr/include/**           the macOS libc headers
//   SDKSettings.json         the SDK version clang's driver reads
//   PROVENANCE               where every byte came from, and its license
//
// Sources, both pinned by sha256 and fetched at build time (nothing C is
// committed to this repository):
//   - Zig 0.16.0's source archive (MIT, Copyright (c) Zig contributors):
//     lib/libc/darwin/libSystem.tbd and SDKSettings.json (the stub Zig
//     generates from the macOS 26.4 SDK), lib/libc/include/any-darwin-any
//     (Apple's Libc/xnu/libpthread/libmalloc... headers, APSL-2.0 and BSD
//     licensed per file, as Zig redistributes them). Zig's own releases
//     ship exactly this tree to link for macOS from any host.
//   - LLVM's libc++ ABI list for arm64-apple-darwin at the SDK's LLVM tag
//     (Apache-2.0 WITH LLVM-exception): every symbol libc++.1.dylib exports,
//     including the libc++abi symbols it re-exports. libc++.tbd is generated
//     from it here; the dylib itself is part of every macOS since 10.7.
// Framework stubs are not here: an application that links Cocoa or Metal
// gets them from its dependencies (`with get`), never from this sysroot.
const SDK_ZIG_VERSION: str = "0.16.0"
const SDK_ZIG_TAR_GZ_SHA256: str = "966f170284ac8a1757dd55a092275b2d2a032ef40878f70d84f6a45a3f85f3ae"
const SDK_LIBCXX_ABILIST_NAME: str = "arm64-apple-darwin.libcxxabi.v1.stable.exceptions.nonew.abilist"
const SDK_LIBCXX_ABILIST_SHA256: str = "15f185e6248890bfd4ddce53740b9437cbe5307b1916755d84e4dd96122c3638"

// A merge sort: the sysroot sorts thousands of names (libc++'s symbols), and
// sdk_sort_strings rebuilds its whole list for every insertion.
fn sdk_merge_sort_strings(items: Vec[str]) -> Vec[str]:
    if items.len() <= 1:
        return items
    let mid = items.len() as i32 / 2
    let left: Vec[str] = Vec.new()
    let right: Vec[str] = Vec.new()
    for i in 0..items.len() as i32:
        if i < mid: left.push(sdk_owned_text(items[i])) else: right.push(sdk_owned_text(items[i]))
    let a = sdk_merge_sort_strings(left)
    let b = sdk_merge_sort_strings(right)
    let out: Vec[str] = Vec.new()
    var i = 0
    var j = 0
    while i < a.len() as i32 or j < b.len() as i32:
        if j >= b.len() as i32 or (i < a.len() as i32 and sdk_str_compare(a[i], b[j]) <= 0):
            out.push(sdk_owned_text(a[i]))
            i = i + 1
        else:
            out.push(sdk_owned_text(b[j]))
            j = j + 1
    out

pub fn sdk_zig_source_url() -> str: "https://codeberg.org/ziglang/zig/archive/" ++ SDK_ZIG_VERSION ++ ".tar.gz"
pub fn sdk_zig_source_sha256() -> str: SDK_ZIG_TAR_GZ_SHA256
pub fn sdk_zig_archive() -> str: sdk_source_root() ++ "/zig-" ++ SDK_ZIG_VERSION ++ ".tar.gz"
pub fn sdk_zig_source_root() -> str: sdk_source_root() ++ "/zig-" ++ SDK_ZIG_VERSION
// The archive's top directory is `zig/`.
pub fn sdk_zig_source_dir() -> str: sdk_zig_source_root() ++ "/zig"
pub fn sdk_zig_source_marker() -> str: sdk_zig_source_dir() ++ "/.with-source-ready"

fn sdk_libcxx_abilist_url() -> str:
    "https://raw.githubusercontent.com/llvm/llvm-project/llvmorg-" ++ compiler_llvm_version() ++ "/libcxx/lib/abi/" ++ SDK_LIBCXX_ABILIST_NAME

fn sdk_libcxx_abilist_path() -> str:
    sdk_source_root() ++ "/libcxx-" ++ compiler_llvm_version() ++ "-" ++ SDK_LIBCXX_ABILIST_NAME

// The tree the compiler's own link reads as -syslibroot, and the packed
// form the compiler embeds (src/compiler/EmbeddedSysroot.w reads it).
pub fn sdk_darwin_sysroot_dir() -> str: comp_darwin_sysroot_dir()
pub fn sdk_darwin_sysroot_pack() -> str: "out/gen/darwin-sysroot.pack"

// The symbols libc++.1.dylib defines, from an LLVM ABI list: one Python dict
// per line, `{'is_defined': True, 'name': '__Znwm', 'type': 'I'}`. 'FUNC' and
// 'OBJECT' are the dylib's own, 'I' the libc++abi symbols it re-exports, and
// an undefined entry ('U') is an import, not an export.
pub fn sdk_libcxx_tbd_from_abilist(abilist: &str) -> str:
    var symbols: Vec[str] = Vec.new()
    let key = "'name': '"
    for line in abilist.split("\n"):
        if line.find("'is_defined': True") < 0:
            continue
        let at = line.find(key)
        if at < 0:
            continue
        let rest = line.slice(at + key.len(), line.len())
        let end = rest.find("'")
        if end <= 0:
            continue
        symbols.push(rest.slice(0, end))
    if symbols.len() == 0:
        return ""
    let sorted = sdk_merge_sort_strings(symbols)
    var out = StringBuilder.with_capacity(abilist.len())
    out.push_str("--- !tapi-tbd\n")
    out.push_str("tbd-version:     4\n")
    out.push_str("targets:         [ arm64-macos, arm64e-macos ]\n")
    out.push_str("install-name:    '/usr/lib/libc++.1.dylib'\n")
    out.push_str("current-version: 1.0\n")
    out.push_str("exports:\n")
    out.push_str("  - targets:         [ arm64-macos, arm64e-macos ]\n")
    out.push_str("    symbols:         [ ")
    for i in 0..sorted.len() as i32:
        if i > 0:
            out.push_str(",\n                       ")
        out.push_str("'")
        out.push_str(sorted[i])
        out.push_str("'")
    out.push_str(" ]\n...\n")
    out.to_str()

fn sdk_darwin_sysroot_provenance() -> str:
    var out = "The With darwin sysroot (#1915): what linking a With program and c_import\n"
    out = out ++ "of libc read on macOS. Generated by `with build :darwin-sysroot`.\n\n"
    out = out ++ "usr/lib/libSystem.tbd, usr/include/**, and the SDK version in SDKSettings.json:\n"
    out = out ++ "  Zig " ++ SDK_ZIG_VERSION ++ " source archive " ++ sdk_zig_source_url() ++ "\n"
    out = out ++ "  sha256 " ++ SDK_ZIG_TAR_GZ_SHA256 ++ "\n"
    out = out ++ "  lib/libc/darwin/{libSystem.tbd,SDKSettings.json}, lib/libc/include/any-darwin-any\n"
    out = out ++ "  Zig: MIT (Copyright (c) Zig contributors). The headers are Apple's open\n"
    out = out ++ "  source Libc/xnu/libpthread/libmalloc headers, APSL-2.0 or BSD licensed as\n"
    out = out ++ "  each file states.\n\n"
    out = out ++ "usr/lib/lib{c,m,pthread,dl}.tbd: copies of libSystem.tbd (the Apple SDK's aliases).\n\n"
    out = out ++ "usr/lib/libc++.tbd: generated from LLVM " ++ compiler_llvm_version() ++ "'s libc++ ABI list\n"
    out = out ++ "  " ++ sdk_libcxx_abilist_url() ++ "\n"
    out = out ++ "  sha256 " ++ SDK_LIBCXX_ABILIST_SHA256 ++ "\n"
    out = out ++ "  LLVM: Apache-2.0 WITH LLVM-exception.\n"
    out

fn sdk_sysroot_path_ok(rel: &str) -> bool:
    if rel.len() == 0 or rel.starts_with("/") or rel.find("..") >= 0:
        return false
    rel.find(" ") < 0 and rel.find("\n") < 0

pub fn run_darwin_sysroot_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let pack_path = ctx.output()
    if pack_path.len() == 0:
        return sdk_fail(ctx, "requires an output path")
    // Only a macOS compiler embeds the darwin sysroot; every other host's
    // compiler carries a zero-length blob (and fetches nothing).
    if os() != "Macos":
        return sdk_write_text(ctx, pack_path, "")
    let scratch = sdk_join("out/command", ctx.target_name())
    if fs.mkdir_all(scratch) != 0:
        return sdk_fail(ctx, "could not create " ++ scratch)
    let abilist_path = sdk_libcxx_abilist_path()
    if not fs.exists(abilist_path) or fs.sha256_file(abilist_path) != SDK_LIBCXX_ABILIST_SHA256:
        let _stale = fs.remove_file(abilist_path)
        let rc = sdk_fetch(ctx, scratch, "libcxx-abilist", sdk_libcxx_abilist_url(), abilist_path, 300000)
        if rc != 0:
            return rc
    let abilist_sha = fs.sha256_file(abilist_path)
    if abilist_sha != SDK_LIBCXX_ABILIST_SHA256:
        return sdk_fail(ctx, sdk_libcxx_abilist_url() ++ " has sha256 " ++ abilist_sha ++ ", expected " ++ SDK_LIBCXX_ABILIST_SHA256)
    let libcxx_tbd = sdk_libcxx_tbd_from_abilist(fs.read_text(abilist_path))
    if libcxx_tbd.len() == 0:
        return sdk_fail(ctx, "no defined symbols in " ++ abilist_path)
    let zig_libc = sdk_join(sdk_zig_source_dir(), "lib/libc")
    let libsystem = fs.read_text(sdk_join(zig_libc, "darwin/libSystem.tbd"))
    let settings = fs.read_text(sdk_join(zig_libc, "darwin/SDKSettings.json"))
    if libsystem.len() == 0 or settings.len() == 0:
        return sdk_fail(ctx, "the Zig " ++ SDK_ZIG_VERSION ++ " source at " ++ sdk_zig_source_dir() ++ " has no lib/libc/darwin/{libSystem.tbd,SDKSettings.json}")
    let include_root = sdk_join(zig_libc, "include/any-darwin-any")
    let headers = sdk_merge_sort_strings(fs.list_files(include_root))
    if headers.len() == 0:
        return sdk_fail(ctx, "no macOS libc headers under " ++ include_root)
    // The tree is rebuilt whole: a header dropped by a newer pin must not
    // linger in it.
    let tree = sdk_darwin_sysroot_dir()
    let _old = fs.remove_tree(tree)
    let rel_paths: Vec[str] = Vec.new()
    let contents: Vec[str] = Vec.new()
    rel_paths.push("PROVENANCE")
    contents.push(sdk_darwin_sysroot_provenance())
    // clang's driver reads the SDK version from SDKSettings.json and needs
    // Version and MaximumDeploymentTarget; Zig's names the version only.
    let version_key = "\"MinimalDisplayName\":\""
    let version_at = settings.find(version_key)
    if version_at < 0:
        return sdk_fail(ctx, "no MinimalDisplayName in Zig's darwin SDKSettings.json: " ++ settings)
    let version_rest = settings.slice(version_at + version_key.len(), settings.len())
    let sdk_version = version_rest.slice(0, version_rest.find("\""))
    rel_paths.push("SDKSettings.json")
    contents.push("{\"CanonicalName\":\"macosx" ++ sdk_version ++ "\",\"Version\":\"" ++ sdk_version ++ "\",\"MaximumDeploymentTarget\":\"" ++ sdk_version ++ ".99\"}\n")
    rel_paths.push("usr/lib/libSystem.tbd")
    contents.push(libsystem.clone())
    rel_paths.push("usr/lib/libc++.tbd")
    contents.push(libcxx_tbd)
    for i in 0..headers.len() as i32:
        let rel = sdk_rel_path(include_root, sdk_normalize(headers[i]))
        if not sdk_sysroot_path_ok(rel):
            return sdk_fail(ctx, "a header path the sysroot pack cannot carry: " ++ headers[i])
        rel_paths.push("usr/include/" ++ rel)
        contents.push(fs.read_text(headers[i]))
    let aliases: Vec[str] = Vec.new()
    aliases.push("usr/lib/libc.tbd")
    aliases.push("usr/lib/libm.tbd")
    aliases.push("usr/lib/libpthread.tbd")
    aliases.push("usr/lib/libdl.tbd")
    // "F <path> <size>\n<bytes>" per file, "A <path> <target>\n" per alias.
    var pack = StringBuilder.with_capacity(12000000)
    pack.push_str("WITH-SYSROOT 1\n")
    for i in 0..rel_paths.len() as i32:
        let rc = sdk_write_text(ctx, sdk_join(tree, rel_paths[i]), contents[i])
        if rc != 0:
            return rc
        pack.push_str("F " ++ rel_paths[i] ++ " " ++ f"{contents[i].len()}" ++ "\n")
        pack.push_str(contents[i])
    for i in 0..aliases.len() as i32:
        let rc = sdk_write_text(ctx, sdk_join(tree, aliases[i]), libsystem)
        if rc != 0:
            return rc
        pack.push_str("A " ++ aliases[i] ++ " usr/lib/libSystem.tbd\n")
    sdk_write_text(ctx, pack_path, pack.to_str())

// ── The SDK's build tools, carried by the compiler (#1915, D81) ────────
//
// `with get` builds a package from source with CMake and Ninja. They are our
// SDK's (sdk-cmake, sdk-ninja build them into the SDK prefix, and the SDK
// package ships bin/cmake, bin/ninja and share/cmake-<v>), never the
// machine's: the compiler embeds them as the `sdk_tools` blob and unpacks
// them to its cache on first use (src/compiler/EmbeddedSysroot.w). Same pack
// format as the darwin sysroot; "E" marks an executable. CMake's Help/ (the
// reference manual, whose file names carry spaces) is left out: CMake does
// not read it to configure or build. macOS only for now; every other host
// carries an empty pack until its #1915 slice.
pub fn sdk_build_tools_pack() -> str: "out/gen/sdk-tools.pack"

pub fn run_sdk_build_tools_pack_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let pack_path = ctx.output()
    if pack_path.len() == 0:
        return sdk_fail(ctx, "requires an output path")
    if os() != "Macos":
        return sdk_write_text(ctx, pack_path, "")
    // The in-project SDK path: the build's file sandbox reads under the
    // project root (as build/clang_resource.w does).
    let prefix = compiler_default_llvm_prefix()
    let share = sdk_join(prefix, sdk_cmake_data_prefix().slice(0, sdk_cmake_data_prefix().len() - 1))
    var pack = StringBuilder.with_capacity(48000000)
    pack.push_str("WITH-SYSROOT 1\n")
    let tools: Vec[str] = Vec.new()
    tools.push("bin/cmake")
    tools.push("bin/ninja")
    for i in 0..tools.len() as i32:
        let bytes = fs.read_text(sdk_join(prefix, tools[i]))
        if bytes.len() == 0:
            return sdk_fail(ctx, "the LLVM SDK at " ++ prefix ++ " has no " ++ tools[i] ++ " (sdk-cmake / sdk-ninja build it; the SDK package ships it)")
        pack.push_str("E " ++ tools[i] ++ " " ++ f"{bytes.len()}" ++ "\n")
        pack.push_str(bytes)
    let files = sdk_merge_sort_strings(fs.list_files(share))
    if files.len() == 0:
        return sdk_fail(ctx, "the LLVM SDK at " ++ prefix ++ " has no CMake modules under " ++ share)
    var count = 0
    for i in 0..files.len() as i32:
        let rel = sdk_rel_path(prefix, sdk_normalize(files[i]))
        if rel.len() == 0 or rel.find("/Help/") >= 0:
            continue
        if not sdk_sysroot_path_ok(rel):
            return sdk_fail(ctx, "a CMake file the tools pack cannot carry: " ++ files[i])
        let bytes = fs.read_text(files[i])
        pack.push_str("F " ++ rel ++ " " ++ f"{bytes.len()}" ++ "\n")
        pack.push_str(bytes)
        count = count + 1
    if count < 100:
        return sdk_fail(ctx, f"only {count} CMake module files under " ++ share)
    sdk_write_text(ctx, pack_path, pack.to_str())
// ── The Windows C runtime the SDK carries (#1915) ─────────────────────────
//
// A With program and the With compiler link on Windows against nothing but
// this SDK and the DLLs Windows ships in the box (Eric, 2026-09-29): no
// Visual Studio, no Windows Kits. The C runtime underneath is mingw-w64's,
// built the way Zig builds it (.reference/zig/src/libs/mingw.zig) and the way
// mingw-w64's own mingw-w64-crt/Makefile.am does: the headers, the UCRT
// startup objects and support libraries compiled from source by the SDK's
// clang, and the import libraries of the in-box DLLs generated from
// mingw-w64's .def files by the SDK's llvm-dlltool. The sources are fetched
// at SDK build time from the pinned release tag, exactly like LLVM's; nothing
// of them is checked into this repository. Programs run against ucrtbase and
// the api-ms-win-crt-* API sets (in the box since Windows 10), never
// vcruntime140/msvcp140.
//
// Layout, under <sdk>/libc/windows (the sysroot clang's MinGW driver reads
// with --sysroot):
//   include/                      the headers, shared by every architecture
//   <arch>-w64-mingw32/lib/       crt2.o crtbegin.o crtend.o, mingw32.lib
//                                 mingwex.lib moldname.lib ucrt.lib msvcrt.lib,
//                                 and one <dll>.lib per in-box DLL below
//   COPYING* DISCLAIMER* PROVENANCE
// compiler-rt's builtins for the target go where clang looks for them:
// <sdk>/lib/clang/<major>/lib/windows/libclang_rt.builtins-<arch>.a.

const SDK_MINGW_W64_VERSION: str = "14.0.0"
const SDK_MINGW_W64_SHA256: str = "d71cc644cd5a37c337f2719f3e0c79d89e8d8d5fb9e2952a62d3fa23623dc137"

pub fn sdk_mingw_source_url() -> str:
    "https://github.com/mingw-w64/mingw-w64/archive/refs/tags/v" ++ SDK_MINGW_W64_VERSION ++ ".tar.gz"

pub fn sdk_mingw_source_sha256() -> str: SDK_MINGW_W64_SHA256

pub fn sdk_mingw_archive() -> str: sdk_source_root() ++ "/mingw-w64-v" ++ SDK_MINGW_W64_VERSION ++ ".tar.gz"

pub fn sdk_mingw_source_dir() -> str: sdk_source_root() ++ "/mingw-w64-" ++ SDK_MINGW_W64_VERSION

pub fn sdk_mingw_source_marker() -> str: sdk_mingw_source_dir() ++ "/.with-source-ready"

pub fn sdk_windows_libc_root(prefix: &str) -> str: sdk_join(prefix, "libc/windows")

pub fn sdk_windows_libc_triple_dir(arch_name: &str) -> str: arch_name ++ "-w64-mingw32"

pub fn sdk_windows_libc_lib_dir(prefix: &str, arch_name: &str) -> str:
    sdk_windows_libc_root(prefix) ++ "/" ++ sdk_windows_libc_triple_dir(arch_name) ++ "/lib"

// The marker a finished libc build leaves: the startup object every program
// links first.
pub fn sdk_windows_libc_marker(prefix: &str, arch_name: &str) -> str:
    sdk_windows_libc_lib_dir(prefix, arch_name) ++ "/crt2.o"

pub fn sdk_compiler_rt_builtins(prefix: &str, arch_name: &str) -> str:
    sdk_join(prefix, "lib/clang/" ++ sdk_llvm_major() ++ "/lib/windows/libclang_rt.builtins-" ++ arch_name ++ ".a")

// The in-box DLLs whose import libraries the SDK carries: what the With
// runtime and the compiler import (dbghelp for backtraces, ws2_32 for
// std.net, advapi32/bcrypt for randomness, the COM and shell pieces LLVM's
// Support library calls), plus the libraries clang's MinGW driver names on
// every link (advapi32 shell32 user32 kernel32), and what the SDK's own
// tools import. A library an application
// pulls in (opengl32, gdi32, winmm, ...) is that application's dependency,
// fetched by `with get` or linked by hand; it is not here.
fn sdk_windows_import_libs() -> Vec[str]:
    // Pushed one by one: the build layer runs on the pinned seed (#1122).
    var names: Vec[str] = Vec.new()
    names.push("kernel32")
    names.push("ntdll")
    names.push("advapi32")
    names.push("bcrypt")
    names.push("dbghelp")
    names.push("ws2_32")
    names.push("shell32")
    names.push("user32")
    names.push("ole32")
    names.push("oleaut32")
    names.push("version")
    names.push("psapi")
    // The SDK's own cmake.exe (its curl, libarchive and system probes).
    names.push("crypt32")
    names.push("secur32")
    names.push("iphlpapi")
    names.push("powrprof")
    names

fn sdk_windows_triple(arch_name: &str) -> str: arch_name ++ "-w64-windows-gnu"

// This Windows host's architecture in the libc's spelling.
fn sdk_windows_host_arch() -> str: if sdk_current_platform() == "windows-aarch64": "aarch64" else: "x86_64"

// mingw-w64-crt/Makefile.am names each architecture's libraries under its
// own directory prefix (lib64_libmingw32_a_SOURCES, libarm64_...).
fn sdk_mingw_makefile_prefix(arch_name: &str) -> str:
    if arch_name == "x86_64": return "lib64"
    if arch_name == "aarch64": return "libarm64"
    ""

fn sdk_dlltool_machine(arch_name: &str) -> str:
    if arch_name == "x86_64": return "i386:x86-64"
    if arch_name == "aarch64": return "arm64"
    ""

// ── mingw-w64-crt/Makefile.am, read rather than transcribed ─────────────
//
// The source lists and per-library flags come from the Makefile.am of the
// pinned release, so a version bump brings its own lists. Only what the
// build below reads is understood: `name = value` and `name += value`
// assignments (with `\` continuations), `$(name)` references, `if COND` /
// `else` / `endif` over the configure conditionals, and `include`. Every
// configure substitution (`@NAME@`) this build reads has its value named in
// sdk_mingw_subst; one it does not know fails the build.

pub type SdkMakeVar {
    name: str,
    value: str,
}

fn sdk_make_var_get(vars: &Vec[SdkMakeVar], name: &str) -> str:
    for i in 0..vars.len() as i32:
        if vars[i].name == name:
            return sdk_owned_text(vars[i].value)
    ""

fn sdk_make_var_has(vars: &Vec[SdkMakeVar], name: &str) -> bool:
    for i in 0..vars.len() as i32:
        if vars[i].name == name:
            return true
    false

fn sdk_make_var_set(vars: Vec[SdkMakeVar], name: &str, value: &str, append: bool) -> Vec[SdkMakeVar]:
    var out: Vec[SdkMakeVar] = Vec.new()
    var found = false
    for i in 0..vars.len() as i32:
        if vars[i].name == name:
            found = true
            let joined = if append and vars[i].value.len() > 0: vars[i].value ++ " " ++ value else: sdk_owned_text(value)
            out.push(SdkMakeVar { name: sdk_owned_text(name), value: joined })
        else:
            out.push(SdkMakeVar { name: sdk_owned_text(vars[i].name), value: sdk_owned_text(vars[i].value) })
    if not found:
        out.push(SdkMakeVar { name: sdk_owned_text(name), value: sdk_owned_text(value) })
    out

// The automake conditionals of a configure run for `arch_name` with the
// defaults: no w32api package, no ARM64EC, no DFP, no sysroot, no delay-import
// libraries. A conditional not named here is false.
fn sdk_mingw_condition(cond: &str, arch_name: &str) -> bool:
    if cond.starts_with("!"):
        return not sdk_mingw_condition(cond.slice(1, cond.len()), arch_name)
    if cond == "LIB64": return arch_name == "x86_64"
    if cond == "LIBARM64": return arch_name == "aarch64"
    false

fn sdk_is_ident_char(ch: i32) -> bool:
    (ch >= 48 and ch <= 57) or (ch >= 65 and ch <= 90) or (ch >= 97 and ch <= 122) or ch == 95

// Logical lines: a line ending in `\` continues on the next.
fn sdk_make_logical_lines(text: &str) -> Vec[str]:
    let raw = sdk_split_lines(text)
    var out: Vec[str] = Vec.new()
    var pending = ""
    for i in 0..raw.len() as i32:
        var line: str = raw[i].clone()
        if line.ends_with("\r"):
            line = line.slice(0, line.len() - 1)
        if line.ends_with("\\"):
            pending = pending ++ line.slice(0, line.len() - 1) ++ " "
            continue
        out.push(pending ++ line)
        pending = ""
    if pending.len() > 0:
        out.push(pending)
    out

fn sdk_mingw_parse_makefile(ctx: &ActionCtx, path: &str, reldir: &str, arch_name: &str, vars: Vec[SdkMakeVar]) -> Vec[SdkMakeVar]:
    var out = vars
    let lines = sdk_make_logical_lines(ctx.fs().read_text(path))
    // One character per open `if`: '1' when its branch is live, '0' when not
    // (a string, not a Vec[bool]: the build layer also runs in the seed's
    // comptime evaluator).
    var live = ""
    for i in 0..lines.len() as i32:
        let line = lines[i]
        if line.starts_with("\t") or line.starts_with("#"):
            continue
        let trimmed = sdk_trim(line)
        let active = not live.contains("0")
        if trimmed.starts_with("if "):
            live = live ++ (if sdk_mingw_condition(sdk_trim(trimmed.slice(3, trimmed.len())), arch_name): "1" else: "0")
            continue
        if trimmed == "else":
            if live.len() > 0:
                let flipped = if live.ends_with("1"): "0" else: "1"
                live = live.slice(0, live.len() - 1) ++ flipped
            continue
        if trimmed == "endif" or trimmed.starts_with("endif "):
            if live.len() > 0:
                live = live.slice(0, live.len() - 1)
            continue
        if not active:
            continue
        if trimmed.starts_with("include "):
            let inc = sdk_trim(trimmed.slice(8, trimmed.len()))
            let inc_dir = sdk_dirname(inc)
            out = sdk_mingw_parse_makefile(ctx, sdk_join(sdk_dirname(path), inc), inc_dir, arch_name, move out)
            continue
        // An assignment: an identifier, then `=` or `+=`.
        var k = 0
        while k < trimmed.len() as i32 and sdk_is_ident_char(trimmed[k] as i32):
            k = k + 1
        if k == 0:
            continue
        let name = trimmed.slice(0, k as i64)
        var rest = sdk_trim(trimmed.slice(k as i64, trimmed.len()))
        var append = false
        if rest.starts_with("+="):
            append = true
            rest = rest.slice(2, rest.len())
        else if rest.starts_with("="):
            rest = rest.slice(1, rest.len())
        else:
            continue
        let value = sdk_trim(rest).replace("%reldir%", reldir)
        out = sdk_make_var_set(move out, name, value, append)
    out

// Configure substitutions this build reads, with the values configure
// computes for a clang/lld toolchain with default options: lld provides
// __ImageBase, so no IMAGEBASE_CFLAGS; no control-flow guard; warnings are
// not part of the artifact.
fn sdk_mingw_subst_known(name: &str) -> bool:
    name == "IMAGEBASE_CFLAGS" or name == "CFGUARD_CFLAGS" or name == "ADD_C_CXX_WARNING_FLAGS" or name == "ADD_C_ONLY_WARNING_FLAGS" or name == "ADD_CXX_ONLY_WARNING_FLAGS"

// A step that can fail after reporting why (sdk_fail): its text, or its
// list, when ok. (Plain structs, not Option: the build layer runs on the
// pinned seed's evaluator.)
pub type SdkText {
    ok: bool,
    text: str,
}

pub type SdkList {
    ok: bool,
    items: Vec[str],
}

fn sdk_text_fail(): SdkText { ok: false, text: "" }

fn sdk_list_fail() -> SdkList:
    let items: Vec[str] = Vec.new()
    SdkList { ok: false, items }

// `$(name)` references expanded recursively; `@NAME@` substituted.
fn sdk_make_expand(ctx: &ActionCtx, vars: &Vec[SdkMakeVar], text: &str, top_srcdir: &str, depth: i32) -> SdkText:
    if depth > 32:
        let _ = sdk_fail(ctx, "Makefile.am variable expansion too deep: " ++ text)
        return sdk_text_fail()
    var out = ""
    var i = 0
    let n = text.len() as i32
    while i < n:
        let ch = text[i] as i32
        if ch == 36 and i + 1 < n and text[i + 1] as i32 == 40:
            var j = i + 2
            while j < n and text[j] as i32 != 41:
                j = j + 1
            let name = text.slice((i + 2) as i64, j as i64)
            if name == "top_srcdir" or name == "srcdir":
                out = out ++ top_srcdir
            else if sdk_make_var_has(vars, name):
                let inner = sdk_make_expand(ctx, vars, sdk_make_var_get(vars, name), top_srcdir, depth + 1)
                if not inner.ok:
                    return sdk_text_fail()
                out = out ++ inner.text
            else:
                let _ = sdk_fail(ctx, "mingw-w64-crt/Makefile.am references $(" ++ name ++ "), which it does not define")
                return sdk_text_fail()
            i = j + 1
            continue
        if ch == 64:
            var j = i + 1
            while j < n and sdk_is_ident_char(text[j] as i32):
                j = j + 1
            if j < n and j > i + 1 and text[j] as i32 == 64:
                // Every substitution this build reads is empty for the
                // default configure (sdk_mingw_subst_known).
                let name = text.slice((i + 1) as i64, j as i64)
                if not sdk_mingw_subst_known(name):
                    let _ = sdk_fail(ctx, "mingw-w64-crt/Makefile.am needs configure substitution @" ++ name ++ "@, which this build does not define (sdk_mingw_subst_known)")
                    return sdk_text_fail()
                i = j + 1
                continue
        out = out ++ text.slice(i as i64, (i + 1) as i64)
        i = i + 1
    SdkText { ok: true, text: out }

// Leading and trailing spaces, tabs and CRs removed. (Written out, with
// sdk_llvm_major and sdk_read_or_empty: the build layer also runs in the
// pinned seed's comptime evaluator, which has no str.trim.)
fn sdk_trim(text: &str) -> str:
    var start = 0
    var end = text.len() as i32
    while start < end and (text[start] as i32 == 32 or text[start] as i32 == 9 or text[start] as i32 == 13):
        start = start + 1
    while end > start and (text[end - 1] as i32 == 32 or text[end - 1] as i32 == 9 or text[end - 1] as i32 == 13):
        end = end - 1
    text.slice(start as i64, end as i64)

// The clang resource directory's name: LLVM's major version.
fn sdk_llvm_major() -> str:
    let version = compiler_llvm_version()
    var end = 0
    while end < version.len() as i32 and version[end] as i32 != 46:
        end = end + 1
    version.slice(0, end as i64)

fn sdk_read_or_empty(ctx: &ActionCtx, path: &str) -> str:
    if ctx.fs().exists(path): ctx.fs().read_text(path) else: ""

// The index of the last `ch` in `text`, or -1.
fn sdk_last_index(text: &str, ch: i32) -> i32:
    var at = -1
    for i in 0..text.len() as i32:
        if text[i] as i32 == ch:
            at = i
    at

fn sdk_words(text: &str) -> Vec[str]:
    var out: Vec[str] = Vec.new()
    let parts = text.replace("\t", " ").split(" ")
    for i in 0..parts.len() as i32:
        let word = sdk_trim(parts[i])
        if word.len() > 0:
            out.push(sdk_owned_text(word))
    out

// A library's compiled members: its `_SOURCES` minus headers and .def inputs.
fn sdk_mingw_compiled_sources(ctx: &ActionCtx, vars: &Vec[SdkMakeVar], var_name: &str, top_srcdir: &str) -> SdkList:
    if not sdk_make_var_has(vars, var_name):
        let _ = sdk_fail(ctx, "mingw-w64-crt/Makefile.am defines no " ++ var_name)
        return sdk_list_fail()
    let expanded = sdk_make_expand(ctx, vars, sdk_make_var_get(vars, var_name), top_srcdir, 0)
    if not expanded.ok:
        return sdk_list_fail()
    var out: Vec[str] = Vec.new()
    let words = sdk_words(expanded.text)
    for i in 0..words.len() as i32:
        let w = words[i]
        if w.ends_with(".c") or w.ends_with(".S"):
            out.push(sdk_owned_text(w))
        else if not (w.ends_with(".h") or w.ends_with(".def") or w.ends_with(".def.in")):
            let _ = sdk_fail(ctx, var_name ++ " lists " ++ w ++ ", which this build does not know how to compile")
            return sdk_list_fail()
    SdkList { ok: true, items: out }

// ── Headers ──────────────────────────────────────────────────────────────

// Where mingw-w64-headers installs a file (mingw-w64-headers/configure.ac's
// *HEAD_LIST and Makefile.am), relative to include/, or "" for a file it
// does not install: the .idl sources, ChangeLogs, the test cases.
fn sdk_mingw_header_dest(rel: &str) -> str:
    let parts = rel.split("/")
    let base = parts[parts.len() as i32 - 1]
    let dot = sdk_last_index(base, 46)
    let ext = if dot >= 0: base.slice((dot + 1) as i64, base.len()) else: ""
    if parts.len() == 2 and parts[0] == "include":
        if ext == "h" or ext == "c" or ext == "inl" or ext == "dlg" or ext == "h16" or ext == "hxx" or ext == "rh" or ext == "ver":
            return sdk_owned_text(base)
        return ""
    if parts.len() == 3 and parts[0] == "include" and ext == "h":
        let sub = parts[1]
        if sub == "gdiplus" or sub == "wrl" or sub == "GL" or sub == "KHR" or sub == "psdk_inc":
            return sub ++ "/" ++ base
        return ""
    if parts.len() == 4 and parts[0] == "include" and parts[1] == "wrl" and parts[2] == "wrappers" and ext == "h":
        return "wrl/wrappers/" ++ base
    if parts.len() == 2 and parts[0] == "crt":
        if ext == "h" or ext == "inl":
            return sdk_owned_text(base)
        return ""
    if parts.len() == 3 and parts[0] == "crt" and ext == "h":
        if parts[1] == "sys" or parts[1] == "sec_api":
            return parts[1] ++ "/" ++ base
        return ""
    if parts.len() == 4 and parts[0] == "crt" and parts[1] == "sec_api" and parts[2] == "sys" and ext == "h":
        return "sec_api/sys/" ++ base
    if parts.len() == 4 and parts[0] == "ddk" and parts[1] == "include" and parts[2] == "ddk" and ext == "h":
        return "ddk/" ++ base
    ""

// _mingw.h is configure output: the two defaults configure computes with no
// options (--with-default-msvcrt=ucrt, --with-default-win32-winnt=0xa00).
fn sdk_mingw_h(template: &str) -> str:
    template.replace("@DEFAULT_MSVCRT_VERSION@", "0xE00").replace("@DEFAULT_WIN32_WINNT@", "0xa00")

fn sdk_install_mingw_headers(ctx: &ActionCtx, source_dir: &str, include_dir: &str) -> i32:
    let fs = ctx.fs()
    let headers = sdk_join(source_dir, "mingw-w64-headers")
    let files = fs.list_files(headers)
    var installed = 0
    for i in 0..files.len() as i32:
        let rel = sdk_rel_path(headers, files[i])
        if rel == "crt/_mingw.h.in":
            let text = sdk_mingw_h(fs.read_text(files[i]))
            // A substitution left over is one configure makes and this build
            // does not: fail rather than ship a header with @NAME@ in it.
            if text.contains("@DEFAULT_"):
                return sdk_fail(ctx, "crt/_mingw.h.in has a configure substitution sdk_mingw_h does not make")
            if fs.write_text(sdk_join(include_dir, "_mingw.h"), text) != 0:
                return sdk_fail(ctx, "could not write " ++ sdk_join(include_dir, "_mingw.h"))
            installed = installed + 1
            continue
        let dest = sdk_mingw_header_dest(rel)
        if dest.len() == 0:
            continue
        if fs.copy_file(files[i], sdk_join(include_dir, dest)) != 0:
            return sdk_fail(ctx, "could not install header " ++ rel)
        installed = installed + 1
    if not fs.exists(sdk_join(include_dir, "windows.h")) or not fs.exists(sdk_join(include_dir, "stdio.h")) or not fs.exists(sdk_join(include_dir, "_mingw.h")):
        return sdk_fail(ctx, "mingw-w64 header install is missing windows.h, stdio.h or _mingw.h under " ++ include_dir)
    print_str("windows libc: headers -> " ++ include_dir ++ "\n")
    0

// ── Tools ────────────────────────────────────────────────────────────────

// llvm-ar, llvm-lib, llvm-ranlib and llvm-dlltool are one binary that acts on
// the name it is run as, as lld is for ld.lld, lld-link, ld64.lld and
// wasm-ld. A tool the SDK does not ship under the needed name (the
// windows-x86_64 SDKs before #1915 carry llvm-lib.exe and lld-link.exe only)
// is that same binary, copied into this build's tool directory under the name
// that selects the behavior. The SDK package ships every name from #1915 on.
fn sdk_multicall_family(name: &str) -> Vec[str]:
    var names: Vec[str] = Vec.new()
    if name == "llvm-ar" or name == "llvm-lib" or name == "llvm-ranlib" or name == "llvm-dlltool":
        names.push("llvm-ar")
        names.push("llvm-lib")
        names.push("llvm-ranlib")
        names.push("llvm-dlltool")
    else if name == "ld.lld" or name == "lld-link" or name == "ld64.lld" or name == "wasm-ld" or name == "lld":
        names.push("lld")
        names.push("lld-link")
        names.push("ld.lld")
        names.push("ld64.lld")
        names.push("wasm-ld")
    names

// The absolute path of `name` from the SDK at `tools_prefix`, or "" after
// reporting why there is none.
fn sdk_llvm_tool(ctx: &ActionCtx, tools_prefix: &str, tool_dir: &str, name: &str) -> str:
    let fs = ctx.fs()
    let root = ctx.project_info().project_root()
    let direct = sdk_tool(tools_prefix, name)
    if fs.exists(direct):
        return sdk_abs(root, direct)
    let staged = sdk_join(tool_dir, sdk_exe_name(name))
    if fs.exists(staged):
        return sdk_abs(root, staged)
    let family = sdk_multicall_family(name)
    for i in 0..family.len() as i32:
        let sibling = sdk_tool(tools_prefix, family[i])
        if fs.exists(sibling):
            if fs.copy_file(sibling, staged) != 0:
                let _ = sdk_fail(ctx, "could not stage " ++ name ++ " from " ++ sibling)
                return ""
            let _chmod = fs.chmod(staged, 0o755)
            return sdk_abs(root, staged)
    let _ = sdk_fail(ctx, "the SDK at " ++ tools_prefix ++ " has no " ++ name ++ " (nor any binary of its multicall family)")
    ""

// The compile flags every mingw-w64 source gets here beyond Makefile.am's:
// the target, and the SDK's own headers only — clang's builtin headers first,
// as the driver orders them, then the libc headers just installed. -w: the
// warnings are not part of the artifact. -O2 is configure's default CFLAGS
// without -g, so the objects carry no build-machine paths.
fn sdk_mingw_toolchain_flags(root: &str, tools_prefix: &str, include_dir: &str, arch_name: &str) -> Vec[str]:
    var flags: Vec[str] = Vec.new()
    flags.push("--target=" ++ sdk_windows_triple(arch_name))
    flags.push("-nostdinc")
    flags.push("-isystem")
    flags.push(sdk_abs(root, sdk_join(tools_prefix, "lib/clang/" ++ sdk_llvm_major() ++ "/include")))
    flags.push("-isystem")
    flags.push(sdk_abs(root, include_dir))
    flags.push("-O2")
    flags.push("-w")
    flags

fn sdk_object_name(source: &str) -> str:
    let dot = sdk_last_index(source, 46)
    let stem = if dot >= 0: source.slice(0, dot as i64) else: sdk_owned_text(source)
    stem.replace("/", "_") ++ ".o"

// Compiles `sources` (relative to the crt dir) with `flags` into `obj_dir`,
// at most `width` at a time; returns the objects in source order, or not ok
// after reporting every failure.
fn sdk_compile_all(ctx: &ActionCtx, clang: &str, crt_dir: &str, sources: &Vec[str], flags: &Vec[str], obj_dir: &str, width: i32) -> SdkList:
    let root = ctx.project_info().project_root()
    if ctx.fs().mkdir_all(obj_dir) != 0:
        let _ = sdk_fail(ctx, "could not create " ++ obj_dir)
        return sdk_list_fail()
    var jobs: Vec[ParJob] = Vec.new()
    var objects: Vec[str] = Vec.new()
    for i in 0..sources.len() as i32:
        let object = sdk_join(obj_dir, sdk_object_name(sources[i]))
        var argv: Vec[str] = Vec.new()
        argv.push(sdk_owned_text(clang))
        for j in 0..flags.len() as i32:
            argv.push(sdk_owned_text(flags[j]))
        argv.push("-c")
        argv.push(sdk_abs(root, sdk_join(crt_dir, sources[i])))
        argv.push("-o")
        argv.push(sdk_abs(root, object))
        jobs.push(par_job(argv, sdk_abs(root, object ++ ".stdout"), sdk_abs(root, object ++ ".stderr"), 600000))
        objects.push(object)
    let rcs = par_run(ctx, &jobs, width)
    var failed = false
    for i in 0..rcs.len() as i32:
        if rcs[i] != 0:
            failed = true
            let _ = sdk_fail(ctx, f"compiling {sources[i]} failed with exit code {rcs[i]}: " ++ sdk_read_or_empty(ctx, objects[i] ++ ".stderr"))
    if failed:
        return sdk_list_fail()
    SdkList { ok: true, items: objects }

// One archive of `members` (objects and archives, whose members it takes).
fn sdk_archive(ctx: &ActionCtx, ar: &str, output: &str, members: &Vec[str]) -> i32:
    let root = ctx.project_info().project_root()
    let _rm = ctx.fs().remove_file(output)
    if members.len() == 0:
        // An archive with no members is its magic alone (moldname: mingw's
        // is a placeholder too, the aliases live in the UCRT import library).
        if ctx.fs().write_text(output, "!<arch>\n") != 0:
            return sdk_fail(ctx, "could not write " ++ output)
        return 0
    // The members go through a response file: libmingwex has hundreds, past
    // Windows' 32 KiB command line (and the runner's argv limit, #1916).
    var rsp = ""
    for i in 0..members.len() as i32:
        rsp = rsp ++ sdk_abs(root, members[i]) ++ "\n"
    let rsp_path = output ++ ".members.rsp"
    if ctx.fs().write_text(rsp_path, rsp) != 0:
        return sdk_fail(ctx, "could not write " ++ rsp_path)
    var argv: Vec[str] = Vec.new()
    argv.push(sdk_owned_text(ar))
    argv.push("--format=coff")
    argv.push("qcsL")
    argv.push(sdk_abs(root, output))
    argv.push("@" ++ sdk_abs(root, rsp_path))
    let rc = sdk_run_capture(ctx, "archive-" ++ sdk_basename(output), argv, 600000)
    let _rm_rsp = ctx.fs().remove_file(rsp_path)
    rc

// The .def of `name` as mingw-w64-crt's Makefile.am finds it for the
// architecture: its own directory first, then lib-common; a .def.in is run
// through the preprocessor, and a lib-common one has the i386 `@N`
// decorations removed from its export names (the Makefile's sed).
fn sdk_mingw_def(ctx: &ActionCtx, clang: &str, crt_dir: &str, arch_name: &str, name: &str, work_dir: &str) -> str:
    let fs = ctx.fs()
    let root = ctx.project_info().project_root()
    let arch_dir = sdk_mingw_makefile_prefix(arch_name)
    let plain_arch = sdk_join(crt_dir, arch_dir ++ "/" ++ name ++ ".def")
    if fs.exists(plain_arch):
        return plain_arch
    let plain_common = sdk_join(crt_dir, "lib-common/" ++ name ++ ".def")
    var input = sdk_join(crt_dir, arch_dir ++ "/" ++ name ++ ".def.in")
    var common = false
    if not fs.exists(input):
        if fs.exists(plain_common):
            return plain_common
        input = sdk_join(crt_dir, "lib-common/" ++ name ++ ".def.in")
        common = true
        if not fs.exists(input):
            return ""
    let pre = sdk_join(work_dir, name ++ ".pre.def")
    var argv: Vec[str] = Vec.new()
    argv.push(sdk_owned_text(clang))
    argv.push("--target=" ++ sdk_windows_triple(arch_name))
    argv.push("-E")
    argv.push("-P")
    argv.push("-x")
    argv.push("c")
    argv.push("-w")
    argv.push("-I")
    argv.push(sdk_abs(root, sdk_join(crt_dir, "def-include")))
    argv.push(sdk_abs(root, input))
    argv.push("-o")
    argv.push(sdk_abs(root, pre))
    if sdk_run_capture(ctx, "def-" ++ name, argv, 120000) != 0:
        return ""
    if not common:
        return pre
    let lines = sdk_split_lines(fs.read_text(pre))
    var out = ""
    for i in 0..lines.len() as i32:
        out = out ++ sdk_strip_stdcall_suffix(lines[i]) ++ "\n"
    let def = sdk_join(work_dir, name ++ ".def")
    if fs.write_text(def, out) != 0:
        let _ = sdk_fail(ctx, "could not write " ++ def)
        return ""
    def

// `Name@12 rest` -> `Name rest`: the first word loses an `@<digits>` tail.
fn sdk_strip_stdcall_suffix(line: &str) -> str:
    var end = 0
    while end < line.len() as i32 and line[end] as i32 != 32:
        end = end + 1
    let word = line.slice(0, end as i64)
    let at = sdk_last_index(word, 64)
    if at <= 0 or at == word.len() as i32 - 1:
        return sdk_owned_text(line)
    for i in (at + 1)..word.len() as i32:
        let ch = word[i] as i32
        if ch < 48 or ch > 57:
            return sdk_owned_text(line)
    word.slice(0, at as i64) ++ line.slice(end as i64, line.len())

fn sdk_import_lib(ctx: &ActionCtx, dlltool: &str, arch_name: &str, def: &str, output: &str) -> i32:
    let root = ctx.project_info().project_root()
    var argv: Vec[str] = Vec.new()
    argv.push(sdk_owned_text(dlltool))
    argv.push("-m")
    argv.push(sdk_dlltool_machine(arch_name))
    argv.push("-k")
    argv.push("-d")
    argv.push(sdk_abs(root, def))
    argv.push("-l")
    argv.push(sdk_abs(root, output))
    sdk_run_capture(ctx, "dlltool-" ++ sdk_basename(output), argv, 120000)

// The compile flags Makefile.am gives a library's sources: its
// <prefix>_lib<name>_a_CPPFLAGS (else AM_CPPFLAGS), then AM_CFLAGS, or
// AM_CCASFLAGS for assembly.
fn sdk_mingw_lib_flags(ctx: &ActionCtx, vars: &Vec[SdkMakeVar], crt_dir_abs: &str, lib_var: &str, base: &Vec[str], assembler: bool) -> SdkList:
    let cpp_name = lib_var ++ "_CPPFLAGS"
    let cpp = if sdk_make_var_has(vars, cpp_name): sdk_make_var_get(vars, cpp_name) else: "$(AM_CPPFLAGS)"
    let cflags = if assembler: "$(AM_CCASFLAGS)" else: "$(AM_CFLAGS)"
    let expanded = sdk_make_expand(ctx, vars, cpp ++ " " ++ cflags, crt_dir_abs, 0)
    if not expanded.ok:
        return sdk_list_fail()
    var flags: Vec[str] = Vec.new()
    for i in 0..base.len() as i32:
        flags.push(sdk_owned_text(base[i]))
    let words = sdk_words(expanded.text)
    for i in 0..words.len() as i32:
        flags.push(sdk_owned_text(words[i]))
    SdkList { ok: true, items: flags }

// `base` followed by the words of a Makefile.am flag expression.
fn sdk_mingw_flags_for(ctx: &ActionCtx, vars: &Vec[SdkMakeVar], crt_dir_abs: &str, expr: &str, base: &Vec[str]) -> SdkList:
    let expanded = sdk_make_expand(ctx, vars, expr, crt_dir_abs, 0)
    if not expanded.ok:
        return sdk_list_fail()
    var flags: Vec[str] = Vec.new()
    for i in 0..base.len() as i32:
        flags.push(sdk_owned_text(base[i]))
    let words = sdk_words(expanded.text)
    for i in 0..words.len() as i32:
        flags.push(sdk_owned_text(words[i]))
    SdkList { ok: true, items: flags }

// Compiles one Makefile.am library's C and assembly sources.
fn sdk_mingw_lib_objects(ctx: &ActionCtx, vars: &Vec[SdkMakeVar], clang: &str, crt_dir: &str, lib_var: &str, base: &Vec[str], obj_dir: &str, width: i32) -> SdkList:
    let root = ctx.project_info().project_root()
    let crt_abs = sdk_abs(root, crt_dir)
    let all = sdk_mingw_compiled_sources(ctx, vars, lib_var ++ "_SOURCES", crt_abs)
    if not all.ok:
        return sdk_list_fail()
    var c_sources: Vec[str] = Vec.new()
    var s_sources: Vec[str] = Vec.new()
    for i in 0..all.items.len() as i32:
        let source = sdk_rel_path(crt_abs, all.items[i])
        let rel = if source.len() > 0: source else: sdk_owned_text(all.items[i])
        if rel.ends_with(".S"):
            s_sources.push(rel)
        else:
            c_sources.push(rel)
    var objects: Vec[str] = Vec.new()
    let c_flags = sdk_mingw_lib_flags(ctx, vars, crt_abs, lib_var, base, false)
    if not c_flags.ok:
        return sdk_list_fail()
    let c_objs = sdk_compile_all(ctx, clang, crt_dir, &c_sources, &c_flags.items, obj_dir, width)
    if not c_objs.ok:
        return sdk_list_fail()
    for i in 0..c_objs.items.len() as i32:
        objects.push(sdk_owned_text(c_objs.items[i]))
    if s_sources.len() > 0:
        let s_flags = sdk_mingw_lib_flags(ctx, vars, crt_abs, lib_var, base, true)
        if not s_flags.ok:
            return sdk_list_fail()
        let s_objs = sdk_compile_all(ctx, clang, crt_dir, &s_sources, &s_flags.items, obj_dir, width)
        if not s_objs.ok:
            return sdk_list_fail()
        for i in 0..s_objs.items.len() as i32:
            objects.push(sdk_owned_text(s_objs.items[i]))
    SdkList { ok: true, items: objects }

// ── The libc action ──────────────────────────────────────────────────────

// Toolchain variables clang itself reads from the environment (header
// search paths). The build compiles against the SDK's headers only; one set
// in the environment would add a host directory to every compile.
fn sdk_clang_env_leaks(ctx: &ActionCtx) -> str:
    var names: Vec[str] = Vec.new()
    names.push("CPATH")
    names.push("C_INCLUDE_PATH")
    names.push("CPLUS_INCLUDE_PATH")
    names.push("OBJC_INCLUDE_PATH")
    var set = ""
    for i in 0..names.len() as i32:
        if ctx.env_input(names[i]).len() > 0:
            set = set ++ " " ++ names[i]
    set

// args: tools-prefix (the SDK whose clang and LLVM tools build this),
// output-prefix (the SDK this installs into; it may be the same one — the
// libc is added beside what is there, nothing is replaced), mingw-w64 source
// dir, architecture (x86_64 | aarch64), build dir. Output: the marker.
pub fn run_sdk_windows_libc_action(ctx: ActionCtx) -> i32:
    let args = ctx.args()
    if args.len() < 5:
        return sdk_fail(ctx, "requires tools-prefix, output-prefix, mingw-w64 source dir, arch, and build-dir args")
    let tools_prefix = args.get(0)
    let output_prefix = args.get(1)
    let source_dir = args.get(2)
    let arch_name = args.get(3)
    let build_dir = args.get(4)
    if sdk_mingw_makefile_prefix(arch_name).len() == 0:
        return sdk_fail(ctx, "unsupported Windows libc architecture: " ++ arch_name)
    let leaks = sdk_clang_env_leaks(&ctx)
    if leaks.len() > 0:
        return sdk_fail(ctx, "the environment sets" ++ leaks ++ ", which clang would add to every compile of the SDK's C runtime; unset it")
    let fs = ctx.fs()
    let root = ctx.project_info().project_root()
    let clang = sdk_abs(root, sdk_tool(tools_prefix, "clang"))
    if not fs.exists(sdk_tool(tools_prefix, "clang")):
        return sdk_fail(ctx, "missing SDK clang: " ++ sdk_tool(tools_prefix, "clang"))
    let tool_dir = sdk_join(build_dir, "tools")
    if fs.mkdir_all(tool_dir) != 0:
        return sdk_fail(ctx, "could not create " ++ tool_dir)
    let ar = sdk_llvm_tool(ctx, tools_prefix, tool_dir, "llvm-ar")
    if ar.len() == 0: return 1
    let dlltool = sdk_llvm_tool(ctx, tools_prefix, tool_dir, "llvm-dlltool")
    if dlltool.len() == 0: return 1
    let crt_dir = sdk_join(source_dir, "mingw-w64-crt")
    let libc_root = sdk_windows_libc_root(output_prefix)
    let include_dir = sdk_join(libc_root, "include")
    let lib_dir = sdk_windows_libc_lib_dir(output_prefix, arch_name)
    let work = sdk_join(build_dir, arch_name)
    if fs.mkdir_all(include_dir) != 0 or fs.mkdir_all(lib_dir) != 0 or fs.mkdir_all(work) != 0:
        return sdk_fail(ctx, "could not create the Windows libc directories under " ++ libc_root)
    var rc = sdk_install_mingw_headers(ctx, source_dir, include_dir)
    if rc != 0: return rc
    let width = 16
    let base = sdk_mingw_toolchain_flags(root, tools_prefix, include_dir, arch_name)
    var empty: Vec[SdkMakeVar] = Vec.new()
    let vars = sdk_mingw_parse_makefile(ctx, sdk_join(crt_dir, "Makefile.am"), ".", arch_name, move empty)
    let p = sdk_mingw_makefile_prefix(arch_name)
    let crt_abs = sdk_abs(root, crt_dir)
    let cpp_arch = if arch_name == "x86_64": "$(CPPFLAGS64)" else: "$(CPPFLAGSARM64)"

    // The startup objects: crt2.o is crtexe.c under COMPILE64 (Makefile.am
    // `lib64/crt1.o`, copied to crt2.o); crtbegin.o/crtend.o are the
    // `lib64/%.o: crt/%.c` rule, which clang's MinGW driver links on every
    // executable.
    var startup: Vec[str] = Vec.new()
    startup.push("crt/crtexe.c")
    let startup_flags = sdk_mingw_flags_for(ctx, &vars, crt_abs, cpp_arch ++ " $(extra_include) -D_SYSCRT=1 $(AM_CFLAGS)", &base)
    if not startup_flags.ok: return 1
    let startup_objs = sdk_compile_all(ctx, clang, crt_dir, &startup, &startup_flags.items, sdk_join(work, "crt"), width)
    if not startup_objs.ok: return 1
    if fs.copy_file(startup_objs.items[0], sdk_join(lib_dir, "crt2.o")) != 0:
        return sdk_fail(ctx, "could not install crt2.o")
    var begin_end: Vec[str] = Vec.new()
    begin_end.push("crt/crtbegin.c")
    begin_end.push("crt/crtend.c")
    let be_flags = sdk_mingw_flags_for(ctx, &vars, crt_abs, cpp_arch ++ " $(AM_CFLAGS)", &base)
    if not be_flags.ok: return 1
    let be_objs = sdk_compile_all(ctx, clang, crt_dir, &begin_end, &be_flags.items, sdk_join(work, "crtbeginend"), width)
    if not be_objs.ok: return 1
    if fs.copy_file(be_objs.items[0], sdk_join(lib_dir, "crtbegin.o")) != 0 or fs.copy_file(be_objs.items[1], sdk_join(lib_dir, "crtend.o")) != 0:
        return sdk_fail(ctx, "could not install crtbegin.o/crtend.o")

    // The static support libraries, each from its own Makefile.am source
    // list and flags. moldname's only source is the Makefile's generated
    // placeholder (_libm_dummy.c, one unused static): with the UCRT the old
    // names are aliases in the import library, so its archive is empty.
    var statics: Vec[str] = Vec.new()
    statics.push("mingw32")
    statics.push("mingwex")
    statics.push("uuid")
    for i in 0..statics.len() as i32:
        let name = statics[i]
        let objs = sdk_mingw_lib_objects(ctx, &vars, clang, crt_dir, p ++ "_lib" ++ name ++ "_a", &base, sdk_join(work, name), width)
        if not objs.ok: return 1
        rc = sdk_archive(ctx, ar, sdk_join(lib_dir, name ++ ".lib"), &objs.items)
        if rc != 0: return rc
    let no_members: Vec[str] = Vec.new()
    rc = sdk_archive(ctx, ar, sdk_join(lib_dir, "moldname.lib"), &no_members)
    if rc != 0: return rc

    // The UCRT: lib-common/ucrt.mri's members, the api-ms-win-crt-* import
    // libraries and libucrt_extra's wrappers. msvcrt.lib is the same archive
    // (Makefile.am copies @MSVCRT_LIB@, libucrt.a by default): clang's MinGW
    // driver asks for -lmsvcrt.
    let mri = sdk_split_lines(fs.read_text(sdk_join(crt_dir, "lib-common/ucrt.mri")))
    var ucrt_members: Vec[str] = Vec.new()
    for i in 0..mri.len() as i32:
        let line = sdk_trim(mri[i])
        if not line.starts_with("ADDLIB "):
            continue
        let file = sdk_trim(line.slice(7, line.len()))
        if not file.starts_with("lib") or not file.ends_with(".a"):
            return sdk_fail(ctx, "lib-common/ucrt.mri: unexpected member " ++ file)
        let member = file.slice(3, file.len() - 2)
        if member == "ucrt_extra":
            let objs = sdk_mingw_lib_objects(ctx, &vars, clang, crt_dir, p ++ "_libucrt_extra_a", &base, sdk_join(work, "ucrt_extra"), width)
            if not objs.ok: return 1
            for j in 0..objs.items.len() as i32:
                ucrt_members.push(sdk_owned_text(objs.items[j]))
            continue
        let def = sdk_mingw_def(ctx, clang, crt_dir, arch_name, member, work)
        if def.len() == 0:
            return sdk_fail(ctx, "no .def for " ++ member ++ " in " ++ crt_dir)
        let implib = sdk_join(work, member ++ ".implib.lib")
        rc = sdk_import_lib(ctx, dlltool, arch_name, def, implib)
        if rc != 0: return rc
        ucrt_members.push(implib)
    rc = sdk_archive(ctx, ar, sdk_join(lib_dir, "ucrt.lib"), &ucrt_members)
    if rc != 0: return rc
    if fs.copy_file(sdk_join(lib_dir, "ucrt.lib"), sdk_join(lib_dir, "msvcrt.lib")) != 0:
        return sdk_fail(ctx, "could not install msvcrt.lib")

    // The in-box DLLs' import libraries, each with the objects Makefile.am
    // puts in the same archive (kernel32's out-of-line intrinsics, ws2_32's
    // in6addr helpers, ...).
    let dlls = sdk_windows_import_libs()
    for i in 0..dlls.len() as i32:
        let name = dlls[i]
        let def = sdk_mingw_def(ctx, clang, crt_dir, arch_name, name, work)
        if def.len() == 0:
            return sdk_fail(ctx, "no .def for " ++ name ++ " in " ++ crt_dir)
        let implib = sdk_join(work, name ++ ".implib.lib")
        rc = sdk_import_lib(ctx, dlltool, arch_name, def, implib)
        if rc != 0: return rc
        var members: Vec[str] = Vec.new()
        members.push(implib)
        let lib_var = p ++ "_lib" ++ name ++ "_a"
        if sdk_make_var_has(&vars, lib_var ++ "_SOURCES"):
            let objs = sdk_mingw_lib_objects(ctx, &vars, clang, crt_dir, lib_var, &base, sdk_join(work, name), width)
            if not objs.ok: return 1
            for j in 0..objs.items.len() as i32:
                members.push(sdk_owned_text(objs.items[j]))
        rc = sdk_archive(ctx, ar, sdk_join(lib_dir, name ++ ".lib"), &members)
        if rc != 0: return rc

    // Licenses and provenance travel with the binaries.
    let notices: Vec[str] = Vec.new()
    notices.push("COPYING")
    notices.push("COPYING.MinGW-w64/COPYING.MinGW-w64.txt")
    notices.push("COPYING.MinGW-w64-runtime/COPYING.MinGW-w64-runtime.txt")
    notices.push("DISCLAIMER")
    notices.push("DISCLAIMER.PD")
    for i in 0..notices.len() as i32:
        let src = sdk_join(source_dir, notices[i])
        if not fs.exists(src):
            return sdk_fail(ctx, "mingw-w64 source has no " ++ notices[i])
        if fs.copy_file(src, sdk_join(libc_root, sdk_basename(notices[i]))) != 0:
            return sdk_fail(ctx, "could not install " ++ notices[i])
    let provenance = "mingw-w64 " ++ SDK_MINGW_W64_VERSION ++ "\n" ++
        "source: " ++ sdk_mingw_source_url() ++ "\n" ++
        "sha256: " ++ SDK_MINGW_W64_SHA256 ++ "\n" ++
        "license: ZPL 2.1 with public-domain and BSD-style parts; see COPYING, COPYING.MinGW-w64.txt, COPYING.MinGW-w64-runtime.txt, DISCLAIMER, DISCLAIMER.PD\n" ++
        "built by: with build :sdk-windows-libc (build/sdk.w run_sdk_windows_libc_action), with the SDK's own clang and llvm-dlltool\n" ++
        "include/: mingw-w64-headers, installed as its configure --with-default-msvcrt=ucrt --with-default-win32-winnt=0xa00 would\n" ++
        "<arch>-w64-mingw32/lib/: crt2.o crtbegin.o crtend.o, mingw32 mingwex moldname uuid, ucrt (= msvcrt), and the import libraries of the in-box DLLs, from mingw-w64-crt/Makefile.am\n"
    rc = sdk_write_text(ctx, sdk_join(libc_root, "PROVENANCE"), provenance)
    if rc != 0: return rc
    if not fs.exists(sdk_windows_libc_marker(output_prefix, arch_name)):
        return sdk_fail(ctx, "the Windows libc build did not leave " ++ sdk_windows_libc_marker(output_prefix, arch_name))
    0

// ── compiler-rt's builtins for Windows ─────────────────────────────────────
//
// The mingw-w64 runtime is GNU-ABI code: its stack probes call
// ___chkstk_ms, its math the soft-float and 128-bit helpers, which libgcc
// supplies to a GCC toolchain and compiler-rt's builtins to this one. They
// are built from the LLVM source the SDK is built from, by compiler-rt's own
// standalone CMake project (as llvm-mingw builds them), with the SDK's clang
// against the libc just installed, into the clang resource directory where
// clang's MinGW driver looks for them.
//
// args: tools-prefix, output-prefix, LLVM source dir, arch, build dir.
pub fn run_sdk_compiler_rt_builtins_action(ctx: ActionCtx) -> i32:
    let args = ctx.args()
    if args.len() < 5:
        return sdk_fail(ctx, "requires tools-prefix, output-prefix, LLVM source dir, arch, and build-dir args")
    let tools_prefix = args.get(0)
    let output_prefix = args.get(1)
    let source_dir = args.get(2)
    let arch_name = args.get(3)
    let build_dir = args.get(4)
    if sdk_mingw_makefile_prefix(arch_name).len() == 0:
        return sdk_fail(ctx, "unsupported Windows architecture: " ++ arch_name)
    let leaks = sdk_clang_env_leaks(&ctx)
    if leaks.len() > 0:
        return sdk_fail(ctx, "the environment sets" ++ leaks ++ ", which clang would add to every compile; unset it")
    let fs = ctx.fs()
    let root = ctx.project_info().project_root()
    if not fs.exists(sdk_windows_libc_marker(output_prefix, arch_name)):
        return sdk_fail(ctx, "the Windows libc is not installed in " ++ output_prefix ++ " (run :sdk-windows-libc)")
    let tool_dir = sdk_join(build_dir, "tools")
    let cmake_build = sdk_join(build_dir, arch_name)
    if fs.mkdir_all(tool_dir) != 0 or fs.mkdir_all(cmake_build) != 0:
        return sdk_fail(ctx, "could not create " ++ build_dir)
    let ar = sdk_llvm_tool(ctx, tools_prefix, tool_dir, "llvm-ar")
    if ar.len() == 0: return 1
    let ranlib = sdk_llvm_tool(ctx, tools_prefix, tool_dir, "llvm-ranlib")
    if ranlib.len() == 0: return 1
    let clang = sdk_abs(root, sdk_tool(tools_prefix, "clang"))
    let cmake = sdk_abs(root, sdk_tool(tools_prefix, "cmake"))
    let ninja = sdk_abs(root, sdk_tool(tools_prefix, "ninja"))
    let triple = sdk_windows_triple(arch_name)
    let sysroot = sdk_abs(root, sdk_windows_libc_root(output_prefix))
    let resource = sdk_abs(root, sdk_join(output_prefix, "lib/clang/" ++ sdk_llvm_major()))
    let configure: Vec[str] = Vec.new()
    configure.push(sdk_owned_text(cmake))
    configure.push("-G")
    configure.push("Ninja")
    configure.push("-S")
    configure.push(sdk_abs(root, sdk_join(source_dir, "compiler-rt/lib/builtins")))
    configure.push("-B")
    configure.push(sdk_abs(root, cmake_build))
    configure.push("-DCMAKE_BUILD_TYPE=Release")
    configure.push("-DCMAKE_MAKE_PROGRAM=" ++ ninja)
    configure.push("-DCMAKE_INSTALL_PREFIX=" ++ resource)
    configure.push("-DCMAKE_SYSTEM_NAME=Windows")
    configure.push("-DCMAKE_SYSTEM_PROCESSOR=" ++ (if arch_name == "x86_64": "AMD64" else: "ARM64"))
    configure.push("-DCMAKE_C_COMPILER=" ++ clang)
    configure.push("-DCMAKE_ASM_COMPILER=" ++ clang)
    configure.push("-DCMAKE_C_COMPILER_TARGET=" ++ triple)
    configure.push("-DCMAKE_ASM_COMPILER_TARGET=" ++ triple)
    // Every language the project enables names the SDK compiler and target:
    // a C++ compiler left to CMake is whatever clang++ PATH offers, for the
    // host (MSVC) target, and CMake then does not set MINGW, so compiler-rt
    // names the archive clang_rt.builtins-<arch>.lib, where clang's MinGW
    // driver does not look.
    configure.push("-DCMAKE_CXX_COMPILER=" ++ sdk_abs(root, sdk_tool(tools_prefix, "clang++")))
    configure.push("-DCMAKE_CXX_COMPILER_TARGET=" ++ triple)
    configure.push("-DCMAKE_CXX_COMPILER_WORKS=ON")
    configure.push("-DCMAKE_SYSROOT=" ++ sysroot)
    configure.push("-DCMAKE_AR=" ++ ar)
    configure.push("-DCMAKE_RANLIB=" ++ ranlib)
    configure.push("-DCMAKE_C_COMPILER_WORKS=ON")
    configure.push("-DCMAKE_ASM_COMPILER_WORKS=ON")
    configure.push("-DCMAKE_FIND_ROOT_PATH=" ++ sysroot)
    configure.push("-DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY")
    configure.push("-DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY")
    configure.push("-DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON")
    configure.push("-DCOMPILER_RT_BUILD_BUILTINS=ON")
    configure.push("-DCOMPILER_RT_EXCLUDE_ATOMIC_BUILTIN=OFF")
    configure.push("-DLLVM_ENABLE_PER_TARGET_RUNTIME_DIR=OFF")
    configure.push("-DLLVM_CONFIG_PATH=")
    var rc = sdk_run_capture(ctx, "builtins-configure-" ++ arch_name, configure, 600000)
    if rc != 0: return rc
    var build: Vec[str] = Vec.new()
    build.push(sdk_owned_text(cmake))
    build.push("--build")
    build.push(sdk_abs(root, cmake_build))
    build.push("--target")
    build.push("install")
    rc = sdk_run_capture(ctx, "builtins-build-" ++ arch_name, build, 1800000)
    if rc != 0: return rc
    let installed = sdk_compiler_rt_builtins(output_prefix, arch_name)
    if not fs.exists(installed):
        return sdk_fail(ctx, "compiler-rt's builtins did not install to " ++ installed)
    // From here on the output SDK's clang resource dir is complete, and every
    // Windows-target compile below names it (-resource-dir): its builtins are
    // these, its headers the tools SDK's own — the same LLVM release, which
    // the LLVM install later rewrites with identical files.
    let out_include = sdk_join(output_prefix, "lib/clang/" ++ sdk_llvm_major() ++ "/include")
    if not fs.exists(sdk_join(out_include, "stddef.h")):
        let tools_include = sdk_join(tools_prefix, "lib/clang/" ++ sdk_llvm_major() ++ "/include")
        if fs.copy_tree(tools_include, out_include) != 0:
            return sdk_fail(ctx, "could not stage clang's builtin headers into " ++ out_include)
    0

// ── The Windows GNU-ABI toolchain the SDK's own C++ is built with ─────────
//
// The compiler links LLVM's and clang's C++ archives. Built by clang-cl
// against Visual Studio's STL they need Visual Studio's C++ runtime
// (libcpmt, libcmt, vcruntime) at every compiler link; built for
// <arch>-w64-windows-gnu against the SDK's own libc++ they need nothing but
// the SDK (#1915). These are the CMake arguments every such build shares:
// the tools SDK's clang for the target, the SDK's libc as its sysroot, the
// output SDK's resource dir (compiler-rt's builtins), libc++/libunwind, and
// lld as the linker, all named, nothing found on PATH.
fn sdk_windows_gnu_cmake_args(ctx: &ActionCtx, tools_prefix: &str, output_prefix: &str, arch_name: &str, tool_dir: &str) -> SdkList:
    let root = ctx.project_info().project_root()
    let ar = sdk_llvm_tool(ctx, tools_prefix, tool_dir, "llvm-ar")
    let ranlib = sdk_llvm_tool(ctx, tools_prefix, tool_dir, "llvm-ranlib")
    let ld = sdk_llvm_tool(ctx, tools_prefix, tool_dir, "ld.lld")
    if ar.len() == 0 or ranlib.len() == 0 or ld.len() == 0:
        return sdk_list_fail()
    let triple = sdk_windows_triple(arch_name)
    let clang = sdk_abs(root, sdk_tool(tools_prefix, "clang"))
    let clangxx = sdk_abs(root, sdk_tool(tools_prefix, "clang++"))
    let resource = sdk_abs(root, sdk_join(output_prefix, "lib/clang/" ++ sdk_llvm_major()))
    let sysroot = sdk_abs(root, sdk_windows_libc_root(output_prefix))
    let compile_flags = "-resource-dir=" ++ resource
    let link_flags = "-resource-dir=" ++ resource ++ " --ld-path=" ++ ld ++ " -rtlib=compiler-rt -unwindlib=libunwind -stdlib=libc++ -static"
    var out: Vec[str] = Vec.new()
    out.push("-DCMAKE_SYSTEM_NAME=Windows")
    out.push("-DCMAKE_SYSTEM_PROCESSOR=" ++ (if arch_name == "x86_64": "AMD64" else: "ARM64"))
    out.push("-DCMAKE_C_COMPILER=" ++ clang)
    out.push("-DCMAKE_CXX_COMPILER=" ++ clangxx)
    out.push("-DCMAKE_ASM_COMPILER=" ++ clang)
    out.push("-DCMAKE_C_COMPILER_TARGET=" ++ triple)
    out.push("-DCMAKE_CXX_COMPILER_TARGET=" ++ triple)
    out.push("-DCMAKE_ASM_COMPILER_TARGET=" ++ triple)
    out.push("-DCMAKE_SYSROOT=" ++ sysroot)
    out.push("-DCMAKE_FIND_ROOT_PATH=" ++ sysroot)
    out.push("-DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY")
    out.push("-DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY")
    out.push("-DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY")
    out.push("-DCMAKE_AR=" ++ ar)
    out.push("-DCMAKE_RANLIB=" ++ ranlib)
    out.push("-DCMAKE_C_FLAGS_INIT=" ++ compile_flags)
    out.push("-DCMAKE_CXX_FLAGS_INIT=" ++ compile_flags ++ " -stdlib=libc++")
    out.push("-DCMAKE_ASM_FLAGS_INIT=" ++ compile_flags)
    // CMake's Windows-Clang module appends Visual Studio's default library
    // set to every link (gdi32 winspool comdlg32 oldnames ...), libraries
    // the SDK does not carry and these programs do not use; clang's MinGW
    // driver already names the runtime's own.
    // try_compile's inner projects take them too (LLVM's configure checks
    // link test programs).
    out.push("-DCMAKE_C_STANDARD_LIBRARIES=")
    out.push("-DCMAKE_CXX_STANDARD_LIBRARIES=")
    out.push("-DCMAKE_TRY_COMPILE_PLATFORM_VARIABLES=CMAKE_C_STANDARD_LIBRARIES;CMAKE_CXX_STANDARD_LIBRARIES")
    out.push("-DCMAKE_EXE_LINKER_FLAGS_INIT=" ++ link_flags)
    out.push("-DCMAKE_SHARED_LINKER_FLAGS_INIT=" ++ link_flags)
    out.push("-DCMAKE_MODULE_LINKER_FLAGS_INIT=" ++ link_flags)
    SdkList { ok: true, items: out }

// libunwind, libc++abi and libc++, static, for the Windows target: the C++
// runtime of the SDK's LLVM and clang archives, and so of the compiler's own
// link. The runtimes' own CMake project with llvm-mingw's configuration
// (build-libcxx.sh), installed into the libc's <arch>-w64-mingw32 dir, where
// clang's MinGW driver finds the headers (include/c++/v1) and archives.
//
// args: tools-prefix, output-prefix, LLVM source dir, arch, build dir.
pub fn run_sdk_libcxx_action(ctx: ActionCtx) -> i32:
    let args = ctx.args()
    if args.len() < 5:
        return sdk_fail(ctx, "requires tools-prefix, output-prefix, LLVM source dir, arch, and build-dir args")
    let tools_prefix = args.get(0)
    let output_prefix = args.get(1)
    let source_dir = args.get(2)
    let arch_name = args.get(3)
    let build_dir = args.get(4)
    let leaks = sdk_clang_env_leaks(&ctx)
    if leaks.len() > 0:
        return sdk_fail(ctx, "the environment sets" ++ leaks ++ ", which clang would add to every compile; unset it")
    let fs = ctx.fs()
    let root = ctx.project_info().project_root()
    if not fs.exists(sdk_compiler_rt_builtins(output_prefix, arch_name)):
        return sdk_fail(ctx, "compiler-rt's builtins are not installed in " ++ output_prefix ++ " (run :sdk-compiler-rt-builtins)")
    let tool_dir = sdk_join(build_dir, "tools")
    let cmake_build = sdk_join(build_dir, arch_name)
    if fs.mkdir_all(tool_dir) != 0 or fs.mkdir_all(cmake_build) != 0:
        return sdk_fail(ctx, "could not create " ++ build_dir)
    let common = sdk_windows_gnu_cmake_args(ctx, tools_prefix, output_prefix, arch_name, tool_dir)
    if not common.ok: return 1
    let cmake = sdk_abs(root, sdk_tool(tools_prefix, "cmake"))
    let prefix = sdk_abs(root, sdk_windows_libc_root(output_prefix) ++ "/" ++ sdk_windows_libc_triple_dir(arch_name))
    // clang's MinGW driver searches <sysroot>/<triple>/include/c++/v1, so a
    // libc++ this step installed before would sit beside the build tree's
    // own headers in every compile of the rebuild: the installed copy goes
    // first.
    let installed_headers = sdk_windows_libc_root(output_prefix) ++ "/" ++ sdk_windows_libc_triple_dir(arch_name) ++ "/include/c++"
    if fs.exists(installed_headers) and fs.remove_tree(installed_headers) != 0:
        return sdk_fail(ctx, "could not remove the previous libc++ headers: " ++ installed_headers)
    let configure: Vec[str] = Vec.new()
    configure.push(sdk_owned_text(cmake))
    configure.push("-G")
    configure.push("Ninja")
    configure.push("-S")
    configure.push(sdk_abs(root, sdk_join(source_dir, "runtimes")))
    configure.push("-B")
    configure.push(sdk_abs(root, cmake_build))
    configure.push("-DCMAKE_BUILD_TYPE=Release")
    configure.push("-DCMAKE_MAKE_PROGRAM=" ++ sdk_abs(root, sdk_tool(tools_prefix, "ninja")))
    configure.push("-DCMAKE_INSTALL_PREFIX=" ++ prefix)
    for i in 0..common.items.len() as i32:
        configure.push(sdk_owned_text(common.items[i]))
    configure.push("-DCMAKE_C_COMPILER_WORKS=ON")
    configure.push("-DCMAKE_CXX_COMPILER_WORKS=ON")
    configure.push("-DCMAKE_ASM_COMPILER_WORKS=ON")
    configure.push("-DLLVM_ENABLE_RUNTIMES=libunwind;libcxxabi;libcxx")
    configure.push("-DLIBUNWIND_USE_COMPILER_RT=ON")
    configure.push("-DLIBUNWIND_ENABLE_SHARED=OFF")
    configure.push("-DLIBUNWIND_ENABLE_STATIC=ON")
    configure.push("-DLIBCXX_USE_COMPILER_RT=ON")
    configure.push("-DLIBCXX_ENABLE_SHARED=OFF")
    configure.push("-DLIBCXX_ENABLE_STATIC=ON")
    configure.push("-DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=ON")
    configure.push("-DLIBCXX_CXX_ABI=libcxxabi")
    configure.push("-DLIBCXX_LIBDIR_SUFFIX=")
    configure.push("-DLIBCXX_INCLUDE_TESTS=OFF")
    configure.push("-DLIBCXX_INCLUDE_BENCHMARKS=OFF")
    configure.push("-DLIBCXX_INSTALL_MODULES=OFF")
    configure.push("-DLIBCXX_ENABLE_ABI_LINKER_SCRIPT=OFF")
    configure.push("-DLIBCXXABI_USE_COMPILER_RT=ON")
    configure.push("-DLIBCXXABI_USE_LLVM_UNWINDER=ON")
    configure.push("-DLIBCXXABI_ENABLE_SHARED=OFF")
    configure.push("-DLIBCXXABI_LIBDIR_SUFFIX=")
    var rc = sdk_run_capture(ctx, "libcxx-configure-" ++ arch_name, configure, 900000)
    if rc != 0: return rc
    var build: Vec[str] = Vec.new()
    build.push(sdk_owned_text(cmake))
    build.push("--build")
    build.push(sdk_abs(root, cmake_build))
    build.push("--target")
    build.push("install")
    rc = sdk_run_capture(ctx, "libcxx-build-" ++ arch_name, build, 3600000)
    if rc != 0: return rc
    let names: Vec[str] = Vec.new()
    names.push("libc++.a")
    names.push("libunwind.a")
    for i in 0..names.len() as i32:
        let lib = sdk_join(sdk_windows_libc_lib_dir(output_prefix, arch_name), names[i])
        if not fs.exists(lib):
            return sdk_fail(ctx, "the C++ runtime did not install " ++ lib)
    if not fs.exists(sdk_join(sdk_windows_libc_root(output_prefix), sdk_windows_libc_triple_dir(arch_name) ++ "/include/c++/v1/vector")):
        return sdk_fail(ctx, "libc++'s headers did not install under " ++ prefix ++ "/include/c++/v1")
    0
