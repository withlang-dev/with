module build.compiler

use std.build
use std.process
use std.sysinfo

const COMPILER_LLVM_VERSION: str = "22.1.6"
const COMPILER_FALLBACK_LLVM_PREFIX: str = "/usr/local/llvm"

fn comp_fail(ctx: &ActionCtx, message: str) -> i32:
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

fn comp_is_absolute_path(path: str) -> bool:
    if path.len() == 0:
        return false
    if path.byte_at(0) == 47 or path.byte_at(0) == 92:
        return true
    if os() == "Windows" and path.len() >= 3:
        let drive = path.byte_at(0)
        let colon = path.byte_at(1)
        let slash = path.byte_at(2)
        if colon == 58 and (slash == 47 or slash == 92):
            if (drive >= 65 and drive <= 90) or (drive >= 97 and drive <= 122):
                return true
    false

fn comp_abs(root: str, path: str) -> str:
    if comp_is_absolute_path(path):
        return path
    comp_join(root, path)

fn comp_dirname(path: str) -> str:
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

fn comp_path_basename(path: str) -> str:
    var last_slash: i64 = -1
    for i in 0..path.len() as i32:
        let ch = path.byte_at(i as i64)
        if ch == 47 or ch == 92:
            last_slash = i as i64
    if last_slash >= 0:
        return path.slice(last_slash + 1, path.len())
    path

fn comp_rsp_path(path: str) -> str:
    let normalized = comp_replace_all(path, "\\", "/")
    if comp_index_of(normalized, " ") >= 0:
        return "\"" ++ normalized ++ "\""
    normalized

fn comp_windows_sdk_um_lib(name: str) -> str:
    comp_rsp_path("C:/Program Files (x86)/Windows Kits/10/Lib/10.0.19041.0/um/x64/" ++ name)

fn comp_windows_sdk_ucrt_lib(name: str) -> str:
    comp_rsp_path("C:/Program Files (x86)/Windows Kits/10/Lib/10.0.19041.0/ucrt/x64/" ++ name)

fn comp_windows_msvc_lib(name: str) -> str:
    comp_rsp_path("C:/Program Files (x86)/Microsoft Visual Studio/2019/BuildTools/VC/Tools/MSVC/14.29.30133/lib/x64/" ++ name)

fn comp_linux_system_lib_arg(fs: &ToolFs, name: str) -> str:
    if name == "z":
        if fs.host_exists("/usr/lib/x86_64-linux-gnu/libz.so"):
            return "-lz"
        if fs.host_exists("/usr/lib/x86_64-linux-gnu/libz.so.1"):
            return "/usr/lib/x86_64-linux-gnu/libz.so.1"
    if name == "zstd":
        if fs.host_exists("/usr/lib/x86_64-linux-gnu/libzstd.so"):
            return "-lzstd"
        if fs.host_exists("/usr/lib/x86_64-linux-gnu/libzstd.so.1"):
            return "/usr/lib/x86_64-linux-gnu/libzstd.so.1"
    if name == "xml2":
        if fs.host_exists("/usr/lib/x86_64-linux-gnu/libxml2.so"):
            return "-lxml2"
        if fs.host_exists("/usr/lib/x86_64-linux-gnu/libxml2.so.16"):
            return "/usr/lib/x86_64-linux-gnu/libxml2.so.16"
    "-l" ++ name

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

fn comp_normalize_line_endings(text: str) -> str:
    var has_cr = false
    for ci in 0..text.len() as i32:
        if text.byte_at(ci as i64) == 13:
            has_cr = true
            break
    if not has_cr:
        return text
    var out = ""
    var start = 0
    var i = 0
    while i < text.len() as i32:
        let ch = text.byte_at(i as i64)
        if ch == 13:
            if i > start:
                out = out ++ text.slice(start as i64, i as i64)
            if i + 1 < text.len() as i32 and text.byte_at((i + 1) as i64) == 10:
                i = i + 1
            out = out ++ "\n"
            start = i + 1
        i = i + 1
    if start < text.len() as i32:
        out = out ++ text.slice(start as i64, text.len())
    out

fn comp_tool_from_env(primary: str, legacy: str, fallback: str) -> str:
    let explicit = env(primary)
    if explicit.len() > 0:
        return explicit
    let old = env(legacy)
    if old.len() > 0:
        return old
    fallback

fn comp_default_llvm_prefix() -> str:
    let host_os = os()
    let host_arch = arch()
    if host_os == "Macos" and (host_arch == "armv8" or host_arch == "aarch64"):
        return ".deps/llvm-" ++ COMPILER_LLVM_VERSION ++ "-darwin-arm64"
    if host_os == "Linux" and host_arch == "x86_64":
        return ".deps/llvm-" ++ COMPILER_LLVM_VERSION ++ "-linux-x86_64"
    if host_os == "Windows" and host_arch == "x86_64":
        return ".deps/llvm-" ++ COMPILER_LLVM_VERSION ++ "-windows-x86_64-msvc"
    COMPILER_FALLBACK_LLVM_PREFIX

fn comp_llvm_prefix() -> str:
    let prefix = env("LLVM_PREFIX")
    if prefix.len() > 0:
        return prefix
    comp_default_llvm_prefix()

fn comp_llvm_prefix_for_root(root: str) -> str:
    comp_abs(root, comp_llvm_prefix())

// Exposed so the `deps` target can name the per-platform SDK asset and the
// `.deps/llvm-<ver>-<host>` directory it extracts into.
pub fn compiler_llvm_version() -> str:
    COMPILER_LLVM_VERSION

pub fn compiler_default_llvm_prefix() -> str:
    comp_default_llvm_prefix()

fn comp_llvm_clang_tool(llvm_prefix: str) -> str:
    comp_tool_from_env("WITH_LLVM_CC", "LLVM_CC", llvm_prefix ++ "/bin/clang")

fn comp_llvm_lld_tool(llvm_prefix: str) -> str:
    let fallback = if os() == "Linux":
        llvm_prefix ++ "/bin/ld.lld"
    else if os() == "Windows":
        llvm_prefix ++ "/bin/lld-link.exe"
    else:
        llvm_prefix ++ "/bin/ld64.lld"
    comp_tool_from_env("WITH_LLVM_LD", "LLVM_LD", fallback)

fn comp_libclang_path(llvm_prefix: str) -> str:
    let explicit = env("WITH_LIBCLANG")
    if explicit.len() > 0:
        return explicit
    let legacy = env("LIBCLANG_FILE")
    if legacy.len() > 0:
        return legacy
    if os() == "Windows":
        return llvm_prefix ++ "/lib/libclang.lib"
    llvm_prefix ++ "/lib/libclang.dylib"

fn comp_select_libclang_path(fs: &ToolFs, llvm_prefix: str) -> str:
    let explicit = env("WITH_LIBCLANG")
    if explicit.len() > 0:
        return explicit
    let legacy = env("LIBCLANG_FILE")
    if legacy.len() > 0:
        return legacy
    let static_libclang = llvm_prefix ++ "/lib/libclang.a"
    if fs.host_exists(static_libclang):
        return static_libclang
    let windows_libclang = llvm_prefix ++ "/lib/libclang.lib"
    if fs.host_exists(windows_libclang):
        return windows_libclang
    ""

fn comp_link_path_is_dynamic(path: str) -> bool:
    not path.ends_with(".a") and not path.ends_with(".lib")

pub fn compiler_default_libclang_archive_path() -> str:
    let prefix = compiler_default_llvm_prefix()
    if os() == "Windows":
        return prefix ++ "/lib/libclang.lib"
    prefix ++ "/lib/libclang.a"

fn comp_host_sdk_path(ctx: &ActionCtx) -> str:
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

fn comp_arg_value(args: &Vec[str], prefix: str) -> str:
    for i in 0..args.len() as i32:
        let arg = args.get(i as i64)
        if arg.starts_with(prefix):
            return arg.slice(prefix.len(), arg.len())
    ""

fn comp_arg_allowed_for_compiler(arg: str) -> bool:
    not arg.starts_with("compiler=") and not arg.starts_with("overflow=")

fn comp_host_exe_suffix() -> str:
    if os() == "Windows":
        return ".exe"
    ""

fn comp_path_separator() -> i32:
    if os() == "Windows":
        return 59
    58

fn comp_resolve_seed_compiler(ctx: &ActionCtx) -> str:
    let explicit = env("WITH")
    if explicit.len() > 0:
        return explicit
    let fs = ctx.fs()
    let path_env = env("PATH")
    if path_env.len() > 0:
        var start = 0
        for i in 0..path_env.len() as i32 + 1:
            let at_end = i == path_env.len() as i32
            let is_sep = not at_end and path_env.byte_at(i as i64) == comp_path_separator()
            if is_sep or at_end:
                if i > start:
                    let dir = path_env.slice(start as i64, i as i64)
                    let candidate = dir ++ "/with" ++ comp_host_exe_suffix()
                    if fs.host_exists(candidate):
                        return candidate
                start = i + 1
    if fs.exists("src/main"):
        return "src/main"
    let legacy_compiler = "out/bin/with" ++ comp_host_exe_suffix()
    if fs.exists(legacy_compiler):
        return legacy_compiler
    "with"

fn comp_compiler_path(ctx: &ActionCtx, compiler: str) -> str:
    if compiler == "seed":
        return comp_resolve_seed_compiler(ctx)
    compiler

fn comp_path_exists(ctx: &ActionCtx, path: str) -> bool:
    if path == "with":
        return true
    if comp_is_absolute_path(path):
        return ctx.fs().host_exists(path)
    ctx.fs().exists(path)

fn comp_path_for_process(root: str, path: str) -> str:
    if path == "with":
        return path
    if comp_is_absolute_path(path):
        return path
    comp_abs(root, path)

fn comp_run_compiler_capture(ctx: &ActionCtx, label: str, argv: Vec[str], stdout_path: str, stderr_path: str, timeout_ms: i32) -> i32:
    let root = ctx.project_info().project_root()
    var process_env = process_env()
    process_env = process_env.set("WITH_OUT_DIR", comp_abs(root, "out"))
    let llvm_prefix = env("LLVM_PREFIX")
    if llvm_prefix.len() > 0:
        process_env = process_env.set("LLVM_PREFIX", llvm_prefix)
    let with_llvm_ld = env("WITH_LLVM_LD")
    if with_llvm_ld.len() > 0:
        process_env = process_env.set("WITH_LLVM_LD", with_llvm_ld)
    let llvm_ld = env("LLVM_LD")
    if llvm_ld.len() > 0:
        process_env = process_env.set("LLVM_LD", llvm_ld)
    let with_llvm_cc = env("WITH_LLVM_CC")
    if with_llvm_cc.len() > 0:
        process_env = process_env.set("WITH_LLVM_CC", with_llvm_cc)
    let llvm_cc = env("LLVM_CC")
    if llvm_cc.len() > 0:
        process_env = process_env.set("LLVM_CC", llvm_cc)
    let with_libclang = env("WITH_LIBCLANG")
    if with_libclang.len() > 0:
        process_env = process_env.set("WITH_LIBCLANG", with_libclang)
    let libclang_file = env("LIBCLANG_FILE")
    if libclang_file.len() > 0:
        process_env = process_env.set("LIBCLANG_FILE", libclang_file)
    let overflow_mode = comp_arg_value(ctx.args(), "overflow=")
    if overflow_mode.len() > 0:
        process_env = process_env.set("WITH_INTERNAL_OVERFLOW_MODE", overflow_mode)
    let result = ctx.process_runner().run_capture_with_env(argv, comp_abs(root, stdout_path), comp_abs(root, stderr_path), timeout_ms, process_env)
    if result.rc == 124:
        return comp_fail(ctx, "step '" ++ label ++ "' timed out; stdout=" ++ stdout_path ++ " stderr=" ++ stderr_path)
    if result.rc != 0:
        if result.stderr.len() > 0:
            ctx.diagnostics().error(result.stderr)
        return comp_fail(ctx, "step '" ++ label ++ f"' failed with exit code {result.rc}; stdout=" ++ stdout_path ++ " stderr=" ++ stderr_path)
    let fs = ctx.fs()
    let _stdout = fs.write_text(stdout_path, result.stdout ++ "\n")
    let _stderr = fs.write_text(stderr_path, result.stderr ++ "\n")
    0

fn comp_compile_args(ctx: &ActionCtx, command: str, compiler_path: str, source_path: str) -> Vec[str]:
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

fn comp_remove_file_if_exists(fs: &ToolFs, path: str) -> i32:
    if not fs.exists(path):
        return 0
    fs.remove_file(path)

fn comp_remove_tree_if_exists(fs: &ToolFs, path: str) -> i32:
    if not fs.exists(path):
        return 0
    fs.remove_tree(path)

fn comp_run_first_line(ctx: &ActionCtx, capture_dir: str, label: str, argv: Vec[str], timeout_ms: i32) -> str:
    let root = ctx.project_info().project_root()
    let stdout_path = comp_join(capture_dir, label ++ ".stdout")
    let stderr_path = comp_join(capture_dir, label ++ ".stderr")
    let result = ctx.process_runner().run_capture(argv, comp_abs(root, stdout_path), comp_abs(root, stderr_path), timeout_ms)
    if result.rc != 0:
        return ""
    comp_first_trimmed_line(result.stdout)

fn comp_first_field(text: str) -> str:
    let line = comp_first_trimmed_line(text)
    for i in 0..line.len() as i32:
        let ch = line.byte_at(i as i64)
        if ch == 9 or ch == 32:
            return line.slice(0, i as i64)
    line

fn comp_count_actual_c_export_attrs(text: str) -> i32:
    var count = 0
    var line_start: i64 = 0
    var i: i64 = 0
    while i <= text.len():
        let at_end = i == text.len()
        if at_end or text.byte_at(i) == 10:
            var p = line_start
            while p < i:
                let ch = text.byte_at(p)
                if ch != 9 and ch != 32:
                    break
                p = p + 1
            if p + 11 <= i and text.byte_at(p) == 64:
                if text.byte_at(p + 1) == 91 and text.byte_at(p + 2) == 99 and text.byte_at(p + 3) == 95 and
                    text.byte_at(p + 4) == 101 and text.byte_at(p + 5) == 120 and text.byte_at(p + 6) == 112 and
                    text.byte_at(p + 7) == 111 and text.byte_at(p + 8) == 114 and text.byte_at(p + 9) == 116 and
                    text.byte_at(p + 10) == 40:
                    count = count + 1
            line_start = i + 1
        i = i + 1
    count

fn comp_c_export_budget(path: str) -> i32:
    let _ = path
    -1

fn comp_check_c_export_path(ctx: &ActionCtx, path: str) -> i32:
    if not path.ends_with(".w"):
        return 0
    let text = ctx.fs().read_text(path)
    let count = comp_count_actual_c_export_attrs(text)
    if count == 0:
        return 0
    let budget = comp_c_export_budget(path)
    if budget < 0:
        ctx.diagnostics().error(path ++ ": compiler-owned source has forbidden @[c_export] attributes")
        return 1
    if count > budget:
        ctx.diagnostics().error(path ++ f": @[c_export] count increased from budget {budget} to {count}")
        return 1
    if count < budget:
        ctx.diagnostics().warn(path ++ f": @[c_export] count is now {count}; tighten compiler c_export budget from {budget}")
    0

fn comp_compiler_c_export_audit_files(fs: &ToolFs) -> Vec[str]:
    let roots: Vec[str] = Vec.new()
    roots.push("src")
    roots.push("rt")
    roots.push("lib/std")
    let files: Vec[str] = Vec.new()
    for ri in 0..roots.len() as i32:
        let listing = fs.list_files(roots.get(ri as i64))
        for fi in 0..listing.len() as i32:
            let path = listing.get(fi as i64)
            if path.ends_with(".w"):
                files.push(path)
    comp_sort_strings(files)

fn comp_write_ok_output(ctx: &ActionCtx) -> i32:
    let output = ctx.output()
    if output.len() == 0:
        return 0
    let dir = comp_dirname(output)
    if ctx.fs().mkdir_all(dir) != 0:
        return comp_fail(ctx, "could not create output directory: " ++ dir)
    if ctx.fs().write_text(output, "ok\n") != 0:
        return comp_fail(ctx, "could not write: " ++ output)
    0

fn comp_split_lines(text: str) -> Vec[str]:
    let lines: Vec[str] = Vec.new()
    var start: i64 = 0
    var i: i64 = 0
    while i <= text.len():
        let at_end = i == text.len()
        if at_end or text.byte_at(i) == 10:
            var end = i
            if end > start and text.byte_at(end - 1) == 13:
                end = end - 1
            lines.push(text.slice(start, end))
            start = i + 1
        i = i + 1
    lines

fn comp_requirements_section_30_start(lines: &Vec[str]) -> i32:
    for i in 0..lines.len() as i32:
        if lines.get(i as i64).starts_with("## 30."):
            return i
    -1

fn comp_check_requirements_informative_text(ctx: &ActionCtx, text: str) -> i32:
    if not text.contains("Section 30 is explicitly informative"):
        return comp_fail(ctx, "requirements must state that Section 30 is explicitly informative")
    let lines = comp_split_lines(text)
    let section_start = comp_requirements_section_30_start(lines)
    if section_start < 0:
        return comp_fail(ctx, "requirements missing Section 30")
    var has_trace = false
    for i in section_start..lines.len() as i32:
        let line = lines.get(i as i64)
        if line.contains("Informative trace:"):
            has_trace = true
        if line.contains("  - Requirement:"):
            return comp_fail(ctx, f"docs/requirements.md:{i + 1}: Section 30 must not contain normative Requirement rows")
    if not has_trace:
        return comp_fail(ctx, "requirements Section 30 must include Informative trace:")
    0

fn comp_vec_contains(items: &Vec[str], item: str) -> bool:
    for i in 0..items.len() as i32:
        if items.get(i as i64) == item:
            return true
    false

fn comp_add_unique(items: Vec[str], item: str) -> Vec[str]:
    if item.len() == 0 or comp_vec_contains(items, item):
        return items
    items.push(item)
    items

fn comp_add_words(items: Vec[str], text: str) -> Vec[str]:
    var out = items
    var start = -1
    for i in 0..text.len() as i32:
        let ch = text.byte_at(i as i64)
        let ws = ch == 9 or ch == 10 or ch == 13 or ch == 32
        if ws:
            if start >= 0:
                out = comp_add_unique(out, text.slice(start as i64, i as i64))
                start = -1
        else if start < 0:
            start = i
    if start >= 0:
        out = comp_add_unique(out, text.slice(start as i64, text.len()))
    out

fn comp_is_ident_start(ch: i32) -> bool:
    (ch >= 65 and ch <= 90) or (ch >= 97 and ch <= 122) or ch == 95

fn comp_is_ident_continue(ch: i32) -> bool:
    comp_is_ident_start(ch) or (ch >= 48 and ch <= 57)

fn comp_find_from(text: str, needle: str, start: i32) -> i32:
    if start < 0 or start >= text.len() as i32:
        return -1
    let at = comp_index_of(text.slice(start as i64, text.len()), needle)
    if at < 0:
        return -1
    start + at

fn comp_spec_subsection(text: str, heading: str) -> str:
    let start = comp_index_of(text, heading)
    if start < 0:
        return ""
    var end = text.len() as i32
    var i = start + 1
    while i < text.len() as i32:
        if text.byte_at(i as i64) == 10:
            if i + 4 < text.len() as i32 and text.slice((i + 1) as i64, (i + 4) as i64) == "## ":
                end = i
                break
            if i + 5 < text.len() as i32 and text.slice((i + 1) as i64, (i + 5) as i64) == "### ":
                end = i
                break
        i = i + 1
    text.slice(start as i64, end as i64)

fn comp_first_fenced_block(text: str) -> str:
    let start = comp_index_of(text, "```\n")
    if start < 0:
        return ""
    let body_start = start + 4
    let end = comp_find_from(text, "\n```", body_start)
    if end < 0:
        return ""
    text.slice(body_start as i64, end as i64)

fn comp_collect_quoted_after(text: str, prefix: str) -> Vec[str]:
    var out: Vec[str] = Vec.new()
    var start = 0
    while start < text.len() as i32:
        let at = comp_find_from(text, prefix, start)
        if at < 0:
            break
        let value_start = at + prefix.len() as i32
        let value_end = comp_find_from(text, "\"", value_start)
        if value_end < 0:
            break
        out = comp_add_unique(out, text.slice(value_start as i64, value_end as i64))
        start = value_end + 1
    out

fn comp_collect_attr_names(items: Vec[str], text: str) -> Vec[str]:
    var out = items
    var start = 0
    while start < text.len() as i32:
        let at = comp_find_from(text, "@[", start)
        if at < 0:
            break
        let name_start = at + 2
        if name_start < text.len() as i32 and comp_is_ident_start(text.byte_at(name_start as i64)):
            var name_end = name_start + 1
            while name_end < text.len() as i32 and comp_is_ident_continue(text.byte_at(name_end as i64)):
                name_end = name_end + 1
            out = comp_add_unique(out, text.slice(name_start as i64, name_end as i64))
            start = name_end
        else:
            start = at + 2
    out

fn comp_spec_keywords(spec: str) -> Vec[str]:
    comp_add_words(Vec.new(), comp_first_fenced_block(comp_spec_subsection(spec, "### 29.11 Reserved Keywords")))

fn comp_impl_keywords(fs: &ToolFs) -> Vec[str]:
    comp_collect_quoted_after(fs.read_text("src/Token.w"), "if s == \"")

fn comp_spec_public_attributes(spec: str) -> Vec[str]:
    let lines = comp_split_lines(comp_spec_subsection(spec, "### 29.14 Attribute Index"))
    var attrs: Vec[str] = Vec.new()
    for i in 0..lines.len() as i32:
        let line = lines.get(i as i64)
        if line.starts_with("| `@["):
            var end = -1
            for ci in 1..line.len() as i32:
                if line.byte_at(ci as i64) == 124:
                    end = ci
                    break
            if end > 1:
                attrs = comp_collect_attr_names(attrs, line.slice(1, end as i64))
    attrs

fn comp_spec_internal_attributes(spec: str) -> Vec[str]:
    let lines = comp_split_lines(comp_spec_subsection(spec, "### 29.14 Attribute Index"))
    var attrs: Vec[str] = Vec.new()
    for i in 0..lines.len() as i32:
        let line = lines.get(i as i64)
        if line.starts_with("**Implementation-internal"):
            var j = i
            while j < lines.len() as i32 and comp_trim(lines.get(j as i64)).len() > 0:
                attrs = comp_collect_attr_names(attrs, lines.get(j as i64))
                j = j + 1
    attrs

fn comp_impl_attributes(fs: &ToolFs) -> Vec[str]:
    var text = fs.read_text("src/Parser.w")
    let start = comp_index_of(text, "fn Parser.skip_attributes")
    if start >= 0:
        let marker = comp_find_from(text, "fn Parser.parse_module", start)
        if marker > start:
            text = text.slice(start as i64, marker as i64)
    var attrs = comp_collect_quoted_after(text, "is_ident_named(\"")
    let more = comp_collect_quoted_after(text, "attr_text == \"")
    for i in 0..more.len() as i32:
        attrs = comp_add_unique(attrs, more.get(i as i64))
    attrs

fn comp_strip_comment(text: str) -> str:
    let at = comp_index_of(text, "#")
    if at < 0:
        return text
    text.slice(0, at as i64)

fn comp_first_shell_word(text: str) -> str:
    let trimmed = comp_trim(text)
    for i in 0..trimmed.len() as i32:
        let ch = trimmed.byte_at(i as i64)
        if ch == 9 or ch == 32:
            return trimmed.slice(0, i as i64)
    trimmed

fn comp_spec_cli_commands(spec: str) -> Vec[str]:
    var commands: Vec[str] = Vec.new()
    commands = comp_add_unique(commands, "version")
    commands = comp_add_unique(commands, "help")
    let block = comp_first_fenced_block(comp_spec_subsection(spec, "### 18.5 Toolchain"))
    let lines = comp_split_lines(block)
    for i in 0..lines.len() as i32:
        let stripped = comp_trim(lines.get(i as i64))
        if not stripped.starts_with("with "):
            continue
        let body = comp_trim(comp_strip_comment(stripped.slice(5, stripped.len())))
        var part_start = 0
        var pi = 0
        while pi <= body.len() as i32:
            if pi == body.len() as i32 or body.byte_at(pi as i64) == 124:
                var part = comp_trim(body.slice(part_start as i64, pi as i64))
                if part.starts_with("with "):
                    part = comp_trim(part.slice(5, part.len()))
                let token = comp_first_shell_word(part)
                if token.len() > 0 and not token.starts_with("[") and not token.starts_with("-"):
                    commands = comp_add_unique(commands, token)
                part_start = pi + 1
            pi = pi + 1
    let package_sec = comp_spec_subsection(spec, "### 18.8 Package Management")
    var tick = 0
    while tick < package_sec.len() as i32:
        let open = comp_find_from(package_sec, "`", tick)
        if open < 0:
            break
        let close = comp_find_from(package_sec, "`", open + 1)
        if close < 0:
            break
        let span = comp_trim(package_sec.slice((open + 1) as i64, close as i64))
        if span.starts_with("with "):
            let token = comp_first_shell_word(comp_trim(span.slice(5, span.len())))
            if token.len() > 0 and not token.starts_with("-"):
                commands = comp_add_unique(commands, token)
        tick = close + 1
    commands

fn comp_spec_cli_flags() -> Vec[str]:
    var flags: Vec[str] = Vec.new()
    let defaults = "--release --target --emit-c --emit-obj --overflow --no-std --strict-effects -O0 -O1 -O2 -O3 --open -e -n -p"
    comp_add_words(flags, defaults)

fn comp_impl_commands(fs: &ToolFs) -> Vec[str]:
    let raw = comp_collect_quoted_after(fs.read_text("src/main.w"), "cli_command(argc) == \"")
    var commands: Vec[str] = Vec.new()
    for i in 0..raw.len() as i32:
        let cmd = raw.get(i as i64)
        if not cmd.starts_with("-"):
            commands = comp_add_unique(commands, cmd)
    commands

fn comp_collect_string_literal_flags(items: Vec[str], text: str) -> Vec[str]:
    var flags = items
    var i = 0
    while i < text.len() as i32:
        if text.byte_at(i as i64) != 34:
            i = i + 1
            continue
        var j = i + 1
        while j < text.len() as i32:
            let ch = text.byte_at(j as i64)
            if ch == 92:
                j = j + 2
                continue
            if ch == 34:
                break
            j = j + 1
        if j >= text.len() as i32:
            break
        let literal = text.slice((i + 1) as i64, j as i64)
        if literal.len() >= 2 and literal.byte_at(0) == 45:
            var hyphens = 1
            if literal.len() >= 3 and literal.byte_at(1) == 45:
                hyphens = 2
            if literal.len() > hyphens and comp_is_ident_continue(literal.byte_at(hyphens as i64)):
                var end = hyphens + 1
                while end < literal.len() as i32:
                    let ch = literal.byte_at(end as i64)
                    if not ((ch >= 65 and ch <= 90) or (ch >= 97 and ch <= 122) or (ch >= 48 and ch <= 57) or ch == 45):
                        break
                    end = end + 1
                flags = comp_add_unique(flags, literal.slice(0, end as i64))
        i = j + 1
    flags

fn comp_impl_flags(fs: &ToolFs) -> Vec[str]:
    comp_collect_string_literal_flags(Vec.new(), fs.read_text("src/main.w") ++ "\n" ++ fs.read_text("src/compiler/DriverOptions.w"))

fn comp_spec_modules(spec: str) -> Vec[str]:
    let sec = comp_spec_subsection(spec, "#### Module Map")
    var modules: Vec[str] = Vec.new()
    var tick = 0
    while tick < sec.len() as i32:
        let open = comp_find_from(sec, "`", tick)
        if open < 0:
            break
        let close = comp_find_from(sec, "`", open + 1)
        if close < 0:
            break
        let item = sec.slice((open + 1) as i64, close as i64)
        if item.starts_with("std."):
            modules = comp_add_unique(modules, item)
        tick = close + 1
    modules

fn comp_strip_suffix(text: str, suffix: str) -> str:
    if text.ends_with(suffix):
        return text.slice(0, text.len() - suffix.len())
    text

fn comp_std_module_from_path(path: str) -> str:
    let prefix = "lib/std/"
    if not path.starts_with(prefix):
        return ""
    let rest = path.slice(prefix.len(), path.len())
    if rest.len() == 0 or rest.starts_with("."):
        return ""
    var first = rest
    for i in 0..rest.len() as i32:
        if rest.byte_at(i as i64) == 47:
            first = rest.slice(0, i as i64)
            break
    if first.len() == 0 or first.starts_with("."):
        return ""
    if first.ends_with(".w"):
        first = comp_strip_suffix(first, ".w")
    "std." ++ first

fn comp_impl_modules(fs: &ToolFs) -> Vec[str]:
    let files = fs.list_files("lib/std")
    var modules: Vec[str] = Vec.new()
    for i in 0..files.len() as i32:
        modules = comp_add_unique(modules, comp_std_module_from_path(files.get(i as i64)))
    if fs.exists("lib/std/internal/str_abi.w"):
        modules = comp_add_unique(modules, "std.str_abi")
    modules

fn comp_known_missing_flag(item: str) -> str:
    if item == "--target": return "#425"
    if item == "--open": return "#537"
    ""

fn comp_known_missing_module(item: str) -> str:
    if item == "std.os": return "#476"
    ""

fn comp_known_missing_attribute(item: str) -> str:
    if item == "ffi_stack": return "\302\24714.19 roadmap"
    if item == "align": return "#449"
    if item == "repr": return "#449"
    if item == "target": return "#479"
    ""

fn comp_internal_command(item: str) -> bool:
    item == "ast" or item == "bench" or item == "clean" or item == "get" or item == "install-user" or item == "ir" or item == "lsp" or item == "remove" or item == "tokens"

fn comp_internal_flag(item: str) -> bool:
    item == "--alloc" or item == "--check" or item == "--c-export-functions" or item == "--convert-goto-to-structured" or item == "--deterministic" or item == "--diff" or item == "--dry-run" or item == "--dump-ast" or item == "--dump-async-mir" or item == "--dump-mir" or item == "--dump-project-info" or item == "--dump-resolved" or item == "--dump-tokens" or item == "--dump-typed" or item == "--exclude" or item == "--explain" or item == "--filter" or item == "--force" or item == "--force-reinstall" or item == "--freestanding" or item == "--graph" or item == "--help" or item == "--ir-roundtrip" or item == "--lib" or item == "--migrate-one" or item == "--name" or item == "--no-c-export" or item == "--no-deps" or item == "--no-prelude" or item == "--no-runtime" or item == "--output" or item == "--prefer-brace" or item == "--prefer-colon" or item == "--prefer-curly" or item == "--prelude" or item == "--quiet" or item == "--shared-defs" or item == "--shared-fragment" or item == "--stats" or item == "--verbose" or item == "--width-slice" or item == "--version" or item == "-f" or item == "-D" or item == "-g0" or item == "-h" or item == "-I" or item == "-include" or item == "-l" or item == "-o" or item == "-q" or item == "-v" or item == "-w"

fn comp_internal_module(item: str) -> bool:
    item == "std.builtins" or item == "std.channel" or item == "std.cfg" or item == "std.async" or item == "std.compiler" or item == "std.component" or item == "std.iter" or item == "std.libc" or item == "std.option" or item == "std.prelude" or item == "std.prelude_alloc" or item == "std.prelude_core" or item == "std.re" or item == "std.result" or item == "std.str" or item == "std.str_abi" or item == "std.sys" or item == "std.sysinfo" or item == "std.task" or item == "std.tls" or item == "std.traits"

fn comp_inventory_add_errors(errors: Vec[str], label: str, spec_items: Vec[str], impl_items: Vec[str], known_missing_kind: str, internal_kind: str) -> Vec[str]:
    var out = errors
    let sorted_spec = comp_sort_strings(spec_items)
    for i in 0..sorted_spec.len() as i32:
        let item = sorted_spec.get(i as i64)
        if comp_vec_contains(impl_items, item):
            continue
        let known =
            if known_missing_kind == "flag":
                comp_known_missing_flag(item)
            else if known_missing_kind == "module":
                comp_known_missing_module(item)
            else if known_missing_kind == "attribute":
                comp_known_missing_attribute(item)
            else:
                ""
        if known.len() == 0:
            out.push(label ++ ": missing " ++ item)
    let sorted_impl = comp_sort_strings(impl_items)
    for j in 0..sorted_impl.len() as i32:
        let item = sorted_impl.get(j as i64)
        if comp_vec_contains(sorted_spec, item):
            continue
        let internal =
            if internal_kind == "command":
                comp_internal_command(item)
            else if internal_kind == "flag":
                comp_internal_flag(item)
            else if internal_kind == "module":
                comp_internal_module(item)
            else:
                false
        if not internal:
            out.push(label ++ ": implementation has unspec'd " ++ item)
    out

fn comp_inventory_known_lines() -> Vec[str]:
    var items: Vec[str] = Vec.new()
    items.push("--open\t#537")
    items.push("--target\t#425")
    items.push("align\t#449")
    items.push("ffi_stack\t\302\24714.19 roadmap")
    items.push("repr\t#449")
    items.push("std.os\t#476")
    items.push("target\t#479")
    comp_sort_strings(items)

fn comp_inventory_error_text(errors: Vec[str]) -> str:
    var out = ""
    for i in 0..errors.len() as i32:
        out = out ++ "spec inventory: " ++ errors.get(i as i64) ++ "\n"
    let known = comp_inventory_known_lines()
    for j in 0..known.len() as i32:
        let line = known.get(j as i64)
        let tab = comp_index_of(line, "\t")
        if tab >= 0:
            out = out ++ "spec inventory: known spec-ahead " ++ line.slice(0, tab as i64) ++ " tracked by " ++ line.slice((tab + 1) as i64, line.len()) ++ "\n"
    out

pub fn run_check_compiler_no_new_c_export_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let files = comp_compiler_c_export_audit_files(fs)
    for i in 0..files.len() as i32:
        let rc = comp_check_c_export_path(ctx, files.get(i as i64))
        if rc != 0:
            return rc
    comp_write_ok_output(ctx)

pub fn run_check_requirements_informative_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let path = "docs/requirements.md"
    if not fs.exists(path):
        return comp_fail(ctx, "missing " ++ path)
    let rc = comp_check_requirements_informative_text(ctx, fs.read_text(path))
    if rc != 0:
        return rc
    comp_write_ok_output(ctx)

pub fn run_check_spec_inventory_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let spec_path = "docs/with-specification.md"
    if not fs.exists(spec_path):
        return comp_fail(ctx, "missing " ++ spec_path)
    let spec = fs.read_text(spec_path)
    var errors: Vec[str] = Vec.new()

    errors = comp_inventory_add_errors(errors, "keywords", comp_spec_keywords(spec), comp_impl_keywords(fs), "", "")

    var allowed_attrs = comp_spec_public_attributes(spec)
    let internal_attrs = comp_spec_internal_attributes(spec)
    for ai in 0..internal_attrs.len() as i32:
        allowed_attrs = comp_add_unique(allowed_attrs, internal_attrs.get(ai as i64))
    errors = comp_inventory_add_errors(errors, "attributes", allowed_attrs, comp_impl_attributes(fs), "attribute", "")

    errors = comp_inventory_add_errors(errors, "cli commands", comp_spec_cli_commands(spec), comp_impl_commands(fs), "", "command")
    errors = comp_inventory_add_errors(errors, "cli flags", comp_spec_cli_flags(), comp_impl_flags(fs), "flag", "flag")
    errors = comp_inventory_add_errors(errors, "stdlib modules", comp_spec_modules(spec), comp_impl_modules(fs), "module", "module")

    if errors.len() > 0:
        ctx.diagnostics().error(comp_inventory_error_text(errors))
        return 1
    comp_write_ok_output(ctx)

fn comp_json_escape(text: str) -> str:
    var out = ""
    for i in 0..text.len() as i32:
        let ch = text.byte_at(i as i64)
        if ch == 34:
            out = out ++ "\\\""
        else if ch == 92:
            out = out ++ "\\\\"
        else if ch == 10:
            out = out ++ "\\n"
        else if ch == 13:
            out = out ++ "\\r"
        else if ch == 9:
            out = out ++ "\\t"
        else:
            out = out ++ text.slice(i as i64, (i + 1) as i64)
    out

fn comp_resolve_command_file(ctx: &ActionCtx, capture_dir: str, path: str) -> str:
    if path != "with":
        return comp_abs(ctx.project_info().project_root(), path)
    let which_args: Vec[str] = Vec.new()
    which_args.push("which")
    which_args.push("with")
    let resolved = comp_run_first_line(ctx, capture_dir, "seed-which", which_args, 30000)
    if resolved.len() > 0:
        return resolved
    path

fn comp_sha256_file(ctx: &ActionCtx, capture_dir: str, label: str, path: str) -> str:
    if os() == "Windows":
        let certutil_args: Vec[str] = Vec.new()
        certutil_args.push("certutil")
        certutil_args.push("-hashfile")
        certutil_args.push(path)
        certutil_args.push("SHA256")
        let raw = comp_run_first_line(ctx, capture_dir, label ++ "-certutil", certutil_args, 30000)
        let certutil_text = ctx.fs().read_text(comp_join(capture_dir, label ++ "-certutil.stdout"))
        var line_start: i64 = 0
        for i in 0..certutil_text.len() as i32:
            if certutil_text.byte_at(i as i64) == 10:
                let line = comp_trim(certutil_text.slice(line_start, i as i64))
                if line.len() == 64:
                    return line
                line_start = i as i64 + 1
        if raw.len() == 64:
            return raw
    let shasum_args: Vec[str] = Vec.new()
    shasum_args.push("shasum")
    shasum_args.push("-a")
    shasum_args.push("256")
    shasum_args.push(path)
    let shasum = comp_run_first_line(ctx, capture_dir, label ++ "-shasum", shasum_args, 30000)
    if shasum.len() > 0:
        return comp_first_field(shasum)
    let sha256_args: Vec[str] = Vec.new()
    sha256_args.push("sha256sum")
    sha256_args.push(path)
    let sha256 = comp_run_first_line(ctx, capture_dir, label ++ "-sha256sum", sha256_args, 30000)
    if sha256.len() > 0:
        return comp_first_field(sha256)
    ""

fn comp_record_seed_input(ctx: &ActionCtx, compiler_path: str, capture_dir: str) -> i32:
    let fs = ctx.fs()
    if fs.mkdir_all("out/.build-state") != 0:
        return comp_fail(ctx, "could not create out/.build-state")
    let root = ctx.project_info().project_root()
    let version_args: Vec[str] = Vec.new()
    version_args.push(comp_path_for_process(root, compiler_path))
    version_args.push("version")
    let version = comp_run_first_line(ctx, capture_dir, "seed-version", version_args, 60000)
    if version.len() == 0:
        return comp_fail(ctx, "could not read seed compiler version")
    let resolved_path = comp_resolve_command_file(ctx, capture_dir, compiler_path)
    let sha = comp_sha256_file(ctx, capture_dir, "seed-input", resolved_path)
    if sha.len() == 0:
        return comp_fail(ctx, "could not hash seed compiler: " ++ resolved_path)
    let text =
        "{\n" ++
        "  \"compiler_arg\": \"" ++ comp_json_escape(compiler_path) ++ "\",\n" ++
        "  \"resolved_path\": \"" ++ comp_json_escape(resolved_path) ++ "\",\n" ++
        "  \"version\": \"" ++ comp_json_escape(version) ++ "\",\n" ++
        "  \"sha256\": \"" ++ comp_json_escape(sha) ++ "\"\n" ++
        "}\n"
    if fs.write_text("out/.build-state/seed-input.json", text) != 0:
        return comp_fail(ctx, "could not write out/.build-state/seed-input.json")
    0

fn comp_resolve_compiler_version(ctx: &ActionCtx) -> str:
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

fn comp_read_git_short_hash(fs: &ToolFs, root: str) -> str:
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

fn comp_find_packed_ref(fs: &ToolFs, root: str, ref_path: str) -> str:
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

fn comp_write_versioned_source(ctx: &ActionCtx, source: str, output: str, version: str) -> i32:
    let fs = ctx.fs()
    let text = fs.read_text(source)
    if text.len() == 0:
        return comp_fail(ctx, "could not read source: " ++ source)
    let output_dir = comp_dirname(output)
    if fs.mkdir_all(output_dir) != 0:
        return comp_fail(ctx, "could not create output directory: " ++ output_dir)
    let placeholder = "WITH_VERSION" ++ "_PLACEHOLDER"
    let replaced = comp_normalize_line_endings(comp_replace_all(text, placeholder, version))
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
    let root = ctx.project_info().project_root()
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
    let llvm_prefix = comp_llvm_prefix_for_root(root)
    let llvm_clang = comp_llvm_clang_tool(llvm_prefix)
    let llvm_ld = comp_llvm_lld_tool(llvm_prefix)
    let libclang = comp_select_libclang_path(fs, llvm_prefix)
    if not fs.host_exists(llvm_ld):
        return comp_fail(ctx, "missing LLVM linker: " ++ llvm_ld)
    if libclang.len() == 0:
        return comp_fail(ctx, "missing static libclang archive: " ++ compiler_default_libclang_archive_path())
    if os() == "Windows":
        if not libclang.ends_with(".lib"):
            return comp_fail(ctx, "libclang must be linked statically; expected libclang.lib, got: " ++ libclang)
    else:
        if not libclang.ends_with(".a"):
            return comp_fail(ctx, "libclang must be linked statically; expected libclang.a, got: " ++ libclang)
    if not fs.host_exists(libclang):
        return comp_fail(ctx, "missing static libclang archive: " ++ libclang)
    let llvm_lib_dir = llvm_prefix ++ "/lib"
    let lib_files = fs.host_list_files(llvm_lib_dir)
    if lib_files.len() == 0:
        return comp_fail(ctx, "could not list: " ++ llvm_lib_dir)
    var clang_archives: Vec[str] = Vec.new()
    var llvm_archives: Vec[str] = Vec.new()
    for i in 0..lib_files.len() as i32:
        let path = lib_files.get(i as i64)
        let name = comp_path_basename(path)
        if name.ends_with(".a") or name.ends_with(".lib"):
            if (name.starts_with("libclang") or (os() == "Windows" and name.starts_with("clang"))) and path != libclang:
                clang_archives.push(path)
            else:
                if (name.starts_with("libLLVM") or name.starts_with("LLVM")) and name != "LLVM-C.lib":
                    llvm_archives.push(path)
    var rsp = ""
    var ld_rsp = ""
    rsp = rsp ++ comp_rsp_path(libclang) ++ "\n"
    ld_rsp = ld_rsp ++ comp_rsp_path(libclang) ++ "\n"
    let sorted_clang_archives = comp_sort_strings(clang_archives)
    for i in 0..sorted_clang_archives.len() as i32:
        let path = sorted_clang_archives.get(i as i64)
        rsp = rsp ++ comp_rsp_path(path) ++ "\n"
        ld_rsp = ld_rsp ++ comp_rsp_path(path) ++ "\n"
    let sorted_llvm_archives = comp_sort_strings(llvm_archives)
    for i in 0..sorted_llvm_archives.len() as i32:
        let path = sorted_llvm_archives.get(i as i64)
        rsp = rsp ++ comp_rsp_path(path) ++ "\n"
        ld_rsp = ld_rsp ++ comp_rsp_path(path) ++ "\n"
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
        rsp = rsp ++ comp_linux_system_lib_arg(fs, "z") ++ "\n"
        rsp = rsp ++ comp_linux_system_lib_arg(fs, "zstd") ++ "\n"
        rsp = rsp ++ comp_linux_system_lib_arg(fs, "xml2") ++ "\n"
        ld_rsp = ld_rsp ++ "-Bstatic\n"
        ld_rsp = ld_rsp ++ "-lstdc++\n"
        ld_rsp = ld_rsp ++ "-lgcc\n"
        ld_rsp = ld_rsp ++ "-lgcc_eh\n"
        ld_rsp = ld_rsp ++ "-Bdynamic\n"
        ld_rsp = ld_rsp ++ "-lpthread\n"
        ld_rsp = ld_rsp ++ "-ldl\n"
        ld_rsp = ld_rsp ++ "-lm\n"
        ld_rsp = ld_rsp ++ comp_linux_system_lib_arg(fs, "z") ++ "\n"
        ld_rsp = ld_rsp ++ comp_linux_system_lib_arg(fs, "zstd") ++ "\n"
        ld_rsp = ld_rsp ++ comp_linux_system_lib_arg(fs, "xml2") ++ "\n"
    else if os() == "Windows":
        rsp = rsp ++ comp_windows_msvc_lib("libcpmt.lib") ++ "\n"
        rsp = rsp ++ comp_windows_msvc_lib("libcmt.lib") ++ "\n"
        rsp = rsp ++ comp_windows_msvc_lib("oldnames.lib") ++ "\n"
        rsp = rsp ++ comp_windows_sdk_um_lib("kernel32.lib") ++ "\n"
        rsp = rsp ++ comp_windows_sdk_um_lib("advapi32.lib") ++ "\n"
        rsp = rsp ++ comp_windows_sdk_um_lib("bcrypt.lib") ++ "\n"
        rsp = rsp ++ comp_windows_sdk_um_lib("shell32.lib") ++ "\n"
        rsp = rsp ++ comp_windows_sdk_um_lib("user32.lib") ++ "\n"
        rsp = rsp ++ comp_windows_sdk_um_lib("ole32.lib") ++ "\n"
        rsp = rsp ++ comp_windows_sdk_um_lib("oleaut32.lib") ++ "\n"
        rsp = rsp ++ comp_windows_sdk_um_lib("uuid.lib") ++ "\n"
        rsp = rsp ++ comp_windows_sdk_um_lib("ws2_32.lib") ++ "\n"
        rsp = rsp ++ comp_windows_sdk_um_lib("version.lib") ++ "\n"
        rsp = rsp ++ comp_windows_sdk_um_lib("psapi.lib") ++ "\n"
        rsp = rsp ++ comp_windows_sdk_um_lib("dbghelp.lib") ++ "\n"
        rsp = rsp ++ comp_windows_sdk_um_lib("ntdll.lib") ++ "\n"
        ld_rsp = ld_rsp ++ comp_windows_msvc_lib("libcpmt.lib") ++ "\n"
        ld_rsp = ld_rsp ++ comp_windows_msvc_lib("libcmt.lib") ++ "\n"
        ld_rsp = ld_rsp ++ comp_windows_msvc_lib("oldnames.lib") ++ "\n"
        ld_rsp = ld_rsp ++ comp_windows_sdk_um_lib("kernel32.lib") ++ "\n"
        ld_rsp = ld_rsp ++ comp_windows_sdk_um_lib("advapi32.lib") ++ "\n"
        ld_rsp = ld_rsp ++ comp_windows_sdk_um_lib("bcrypt.lib") ++ "\n"
        ld_rsp = ld_rsp ++ comp_windows_sdk_um_lib("shell32.lib") ++ "\n"
        ld_rsp = ld_rsp ++ comp_windows_sdk_um_lib("user32.lib") ++ "\n"
        ld_rsp = ld_rsp ++ comp_windows_sdk_um_lib("ole32.lib") ++ "\n"
        ld_rsp = ld_rsp ++ comp_windows_sdk_um_lib("oleaut32.lib") ++ "\n"
        ld_rsp = ld_rsp ++ comp_windows_sdk_um_lib("uuid.lib") ++ "\n"
        ld_rsp = ld_rsp ++ comp_windows_sdk_um_lib("ws2_32.lib") ++ "\n"
        ld_rsp = ld_rsp ++ comp_windows_sdk_um_lib("version.lib") ++ "\n"
        ld_rsp = ld_rsp ++ comp_windows_sdk_um_lib("psapi.lib") ++ "\n"
        ld_rsp = ld_rsp ++ comp_windows_sdk_um_lib("dbghelp.lib") ++ "\n"
        ld_rsp = ld_rsp ++ comp_windows_sdk_um_lib("ntdll.lib") ++ "\n"
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
    if compiler_arg == "seed" and ctx.target_name() == "stage1":
        let seed_rc = comp_record_seed_input(ctx, compiler_path, capture_dir)
        if seed_rc != 0:
            return seed_rc
    let stdout_path = comp_join(capture_dir, "stdout.txt")
    let stderr_path = comp_join(capture_dir, "stderr.txt")
    let rc = comp_run_compiler_capture(ctx, "build", argv, stdout_path, stderr_path, 600000)
    if rc != 0:
        let _cleanup_tmp_bin = comp_remove_file_if_exists(fs, tmp_output)
        let _cleanup_tmp_obj = comp_remove_file_if_exists(fs, tmp_output ++ ".o")
        let _cleanup_tmp_dsym_fail = comp_remove_tree_if_exists(fs, tmp_output ++ ".dSYM")
        return rc
    if not fs.exists(tmp_output):
        let _cleanup_tmp_obj_missing = comp_remove_file_if_exists(fs, tmp_output ++ ".o")
        let _cleanup_tmp_dsym_missing = comp_remove_tree_if_exists(fs, tmp_output ++ ".dSYM")
        return comp_fail(ctx, "did not produce output: " ++ tmp_output)
    let _remove_old = comp_remove_file_if_exists(fs, output_path)
    let _remove_old_dsym = comp_remove_tree_if_exists(fs, output_path ++ ".dSYM")
    if fs.rename(tmp_output, output_path) != 0:
        let _cleanup_tmp_bin_rename = comp_remove_file_if_exists(fs, tmp_output)
        let _cleanup_tmp_obj_rename = comp_remove_file_if_exists(fs, tmp_output ++ ".o")
        let _cleanup_tmp_dsym_rename = comp_remove_tree_if_exists(fs, tmp_output ++ ".dSYM")
        return comp_fail(ctx, "could not move output to: " ++ output_path)
    if fs.exists(tmp_output ++ ".dSYM"):
        if fs.rename(tmp_output ++ ".dSYM", output_path ++ ".dSYM") != 0:
            let _cleanup_tmp_dsym_move = comp_remove_tree_if_exists(fs, tmp_output ++ ".dSYM")
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

fn comp_build_source_manifest(fs: &ToolFs) -> str:
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

fn comp_check_manifest(fs: &ToolFs, manifest: str) -> str:
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
        h = h *% 1099511628211
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
