module build.runtime

use std.build
use std.string.StringBuilder
fn runtime_owned_text(s: &str): s ++ ""

fn br_fail(ctx: &ActionCtx, message: &str) -> i32:
    ctx.diagnostics().error("compat-runtime-source: " ++ message)
    1

// Stage-chain ancestor actions live HERE, not in build.w: the root module's
// use closure spans every build/ file, so a root-defined action's signature
// (#686 action_source_paths) would make the stage chain stale on ANY
// build-layer edit. This module's closure is std.build only.
pub fn run_write_empty_file_action(ctx: ActionCtx) -> i32:
    let output = ctx.output()
    if output.len() == 0:
        ctx.diagnostics().error(ctx.target_name() ++ ": missing output")
        return 1
    let dir = br_dirname(output)
    let fs = ctx.fs()
    if fs.mkdir_all(dir) != 0:
        ctx.diagnostics().error(ctx.target_name() ++ ": could not create output directory: " ++ dir)
        return 1
    if fs.write_text(output, "") != 0:
        ctx.diagnostics().error(ctx.target_name() ++ ": could not write: " ++ output)
        return 1
    0

pub fn run_prepare_bootstrap_link_root_action(ctx: ActionCtx) -> i32:
    // Old seed compilers may prefer out/lib before out/bootstrap-lib. Remove
    // stale unversioned runtime probes so stage1 selects the freshly generated
    // bootstrap runtime instead of yesterday's out/lib objects.
    let fs = ctx.fs()
    let stale_runtime_objects: Vec[str] = Vec.new()
    stale_runtime_objects.push("out/lib/cimport_stubs.o")
    stale_runtime_objects.push("out/lib/rt_core.o")
    stale_runtime_objects.push("out/lib/rt_darwin_aarch64.o")
    stale_runtime_objects.push("out/lib/rt_linux_x86_64.o")
    stale_runtime_objects.push("out/lib/rt_windows_x86_64.o")
    stale_runtime_objects.push("out/lib/compat_runtime.o")
    stale_runtime_objects.push("out/lib/panic_runtime.o")
    stale_runtime_objects.push("out/lib/regex_runtime.o")
    stale_runtime_objects.push("out/lib/channel_runtime.o")
    stale_runtime_objects.push("out/lib/fiber_runtime.o")
    stale_runtime_objects.push("out/lib/fiber.o")
    stale_runtime_objects.push("out/lib/fiber_asm.o")
    stale_runtime_objects.push("out/lib/fiber_stubs.o")
    for i in 0..stale_runtime_objects.len() as i32:
        let _remove_stale = fs.remove_file(stale_runtime_objects.get(i as i64))
    let output = ctx.output()
    if fs.mkdir_all(br_dirname(output)) != 0:
        ctx.diagnostics().error(ctx.target_name() ++ ": could not create output directory: " ++ br_dirname(output))
        return 1
    if fs.write_text(output, "ok\n") != 0:
        ctx.diagnostics().error(ctx.target_name() ++ ": could not write: " ++ output)
        return 1
    0

fn br_join(base: &str, child: &str) -> str:
    if child.len() == 0:
        return runtime_owned_text(base)
    if child.byte_at(0) == 47:
        return runtime_owned_text(child)
    if base.len() == 0 or base.ends_with("/"):
        return base ++ child
    base ++ "/" ++ child

fn br_dirname(path: &str) -> str:
    var last = -1
    for i in 0..path.len() as i32:
        if path.byte_at(i as i64) == 47:
            last = i
    if last <= 0:
        return "."
    path.slice(0, last as i64)

fn br_split_nonempty_lines(text: &str) -> Vec[str]:
    let lines: Vec[str] = Vec.new()
    var start = 0
    for i in 0..text.len() as i32:
        if text.byte_at(i as i64) == 10:
            if i > start:
                lines.push(text.slice(start as i64, i as i64))
            start = i + 1
    if start < text.len() as i32:
        lines.push(text.slice(start as i64, text.len()))
    lines

fn br_normalize_path_separators(path: &str) -> str:
    var out = ""
    for i in 0..path.len() as i32:
        let ch = path.byte_at(i as i64)
        if ch == 92:
            out = out ++ "/"
        else:
            out = out ++ path.slice(i as i64, (i + 1) as i64)
    out

fn br_str_compare(a: &str, b: &str) -> i32:
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

fn br_sorted_paths(files: &Vec[str]) -> Vec[str]:
    var sorted: Vec[str] = Vec.new()
    for i in 0..files.len() as i32:
        let path = files.get(i as i64)
        var inserted = false
        var out: Vec[str] = Vec.new()
        for j in 0..sorted.len() as i32:
            let existing = sorted.get(j as i64)
            if not inserted and br_str_compare(path, existing) < 0:
                out.push(runtime_owned_text(path))
                inserted = true
            out.push(runtime_owned_text(existing))
        if not inserted:
            out.push(runtime_owned_text(path))
        sorted = out
    sorted

fn br_collect_runtime_files(ctx: &ActionCtx) -> Vec[str]:
    // D30 R2a: every rt/*.w source embeds (platform selection happens at
    // resolve time). Assembly (.s) stays an object — the sanctioned
    // non-With exception.
    let files: Vec[str] = Vec.new()
    let all_files = br_sorted_paths(ctx.fs().list_files("rt"))
    for i in 0..all_files.len() as i32:
        let path = br_normalize_path_separators(all_files.get(i as i64))
        if path.ends_with(".w"):
            files.push(path)
    files

fn br_collect_stdlib_files(ctx: &ActionCtx) -> Vec[str]:
    let files: Vec[str] = Vec.new()
    let all_files = br_sorted_paths(ctx.fs().list_files("lib/std"))
    for i in 0..all_files.len() as i32:
        let path = br_normalize_path_separators(all_files.get(i as i64))
        if path.ends_with(".w") and not path.starts_with("lib/std/re/"):
            files.push(path)
    files

fn br_contains_delimiter(text: &str, hashes: &str) -> bool:
    let needle = "\"" ++ hashes
    if text.len() < needle.len():
        return false
    var i = 0
    while i <= text.len() as i32 - needle.len() as i32:
        var j = 0
        var matched = true
        while j < needle.len() as i32:
            if text.byte_at((i + j) as i64) != needle.byte_at(j as i64):
                matched = false
                break
            j = j + 1
        if matched:
            return true
        i = i + 1
    false

fn br_raw_string_literal(text: &str) -> str:
    var hashes = ""
    while br_contains_delimiter(text, hashes):
        hashes = hashes ++ "#"
    "r" ++ hashes ++ "\"" ++ text ++ "\"" ++ hashes

fn br_normalize_embedded_source(text: &str) -> str:
    var has_cr = false
    for ci in 0..text.len() as i32:
        if text.byte_at(ci as i64) == 13:
            has_cr = true
            break
    if not has_cr:
        return runtime_owned_text(text)
    var out = StringBuilder.with_capacity(text.len())
    var start = 0
    var i = 0
    while i < text.len() as i32:
        let ch = text.byte_at(i as i64)
        if ch == 13:
            if i > start:
                out.push_str(text.slice(start as i64, i as i64))
            if i + 1 < text.len() as i32 and text.byte_at((i + 1) as i64) == 10:
                i = i + 1
            out.push_str("\n")
            start = i + 1
        i = i + 1
    if start < text.len() as i32:
        out.push_str(text.slice(start as i64, text.len()))
    out.to_str()

fn br_embedded_rel_path(path: &str) -> str:
    if path.starts_with("lib/"):
        return path.slice(4, path.len())
    runtime_owned_text(path)

fn br_generate_embedded_stdlib(ctx: &ActionCtx, files: &Vec[str]) -> str:
    let fs = ctx.fs()
    var out = StringBuilder.new()
    out.push_str("// Auto-generated by with build generate_compat_runtime.\n")
    out.push_str("// Do not edit by hand.\n\n")
    var listing = StringBuilder.new()
    for i in 0..files.len() as i32:
        let path = files.get(i as i64)
        let rel = br_embedded_rel_path(path)
        let source = br_normalize_embedded_source(fs.read_text(path))
        if source.len() == 0:
            ctx.diagnostics().error("compat-runtime-source: failed to read stdlib source: " ++ path)
            return ""
        if source.len() > 500000:
            ctx.diagnostics().error("compat-runtime-source: stdlib source too large: " ++ path)
            return ""
        let sym = f"EMBEDDED_STD_{i}"
        out.push_str("let ")
        out.push_str(sym)
        out.push_str(": str = ")
        out.push_str(br_raw_string_literal(source))
        out.push_str("\n")
        if listing.len() > 0:
            listing.push_str("\n")
        listing.push_str(rel)
    out.push_str("let EMBEDDED_STD_MODULE_LIST: str = ")
    out.push_str(br_raw_string_literal(listing.to_str()))
    out.push_str("\n\n")
    out.push_str("pub fn embedded_std_source_data(path: &str) -> str:\n")
    for i in 0..files.len() as i32:
        let path = files.get(i as i64)
        let rel = br_embedded_rel_path(path)
        let sym = f"EMBEDDED_STD_{i}"
        out.push_str("    if path == ")
        out.push_str(br_raw_string_literal(rel))
        out.push_str(":\n")
        out.push_str("        return ")
        out.push_str(sym)
        out.push_str("\n")
    out.push_str("    return \"\"\n\n")
    out.push_str("pub fn embedded_std_list_modules_data() -> str:\n")
    out.push_str("    return EMBEDDED_STD_MODULE_LIST\n")
    out.to_str()

// D38: the embedded .wo bundle index, consumed by src/compiler/EmbeddedBundles.w.
// `names` are the bundles the build embeds (the embed_object_files target
// carries blobs `wo_<name>_o` and `wo_<name>_manifest` for each); with none,
// the module reports a count of zero and no extern blob symbols exist.
fn br_generate_embedded_bundles(names: &Vec[str]) -> str:
    var out = StringBuilder.new()
    out.push_str("// Auto-generated by with build (compat-runtime-source) - do not edit.\n")
    out.push_str("// Embedded .wo bundle index: see src/compiler/EmbeddedBundles.w.\n\n")
    for i in 0..names.len() as i32:
        let name = names.get(i as i64)
        out.push_str("extern let with_embedded_wo_" ++ name ++ "_o_start: u8\n")
        out.push_str("extern let with_embedded_wo_" ++ name ++ "_o_end: u8\n")
        out.push_str("extern let with_embedded_wo_" ++ name ++ "_manifest_start: u8\n")
        out.push_str("extern let with_embedded_wo_" ++ name ++ "_manifest_end: u8\n")
        out.push_str("extern let with_embedded_wo_" ++ name ++ "_wi_start: u8\n")
        out.push_str("extern let with_embedded_wo_" ++ name ++ "_wi_end: u8\n")
    out.push_str(f"\npub fn embedded_bundles_count_data() -> i32: {names.len() as i32}\n\n")
    out.push_str("pub fn embedded_bundles_name_data(index: i32) -> str:\n")
    for i in 0..names.len() as i32:
        out.push_str(f"    if index == {i}: return \"" ++ names.get(i as i64) ++ "\"\n")
    out.push_str("    \"\"\n\n")
    let kinds: Vec[str] = Vec.new()
    kinds.push("manifest_start")
    kinds.push("manifest_end")
    kinds.push("object_start")
    kinds.push("object_end")
    kinds.push("interface_start")
    kinds.push("interface_end")
    for ki in 0..kinds.len() as i32:
        let kind = kinds.get(ki as i64)
        let blob = if kind.starts_with("manifest"): "manifest" else if kind.starts_with("interface"): "wi" else: "o"
        let edge = if kind.ends_with("start"): "start" else: "end"
        out.push_str("pub fn embedded_bundles_" ++ kind ++ "_data(index: i32) -> i64:\n")
        for i in 0..names.len() as i32:
            out.push_str(f"    if index == {i}: return (&with_embedded_wo_" ++ names.get(i as i64) ++ "_" ++ blob ++ "_" ++ edge ++ " as *const u8) as i64\n")
        out.push_str("    0\n\n")
    out.to_str()

fn br_generate_embedded_runtime(ctx: &ActionCtx, files: &Vec[str]) -> str:
    // D30 R2a: the runtime embeds exactly like the stdlib, keyed by its
    // repo-relative path ("rt/rt_core.w"). Consumed via
    // src/compiler/EmbeddedRuntime.w under the <embedded-rt>/ prefix.
    let fs = ctx.fs()
    var out = StringBuilder.new()
    out.push_str("// Auto-generated by with build generate_compat_runtime.\n")
    out.push_str("// Do not edit by hand.\n\n")
    var listing = StringBuilder.new()
    for i in 0..files.len() as i32:
        let path = files.get(i as i64)
        let source = br_normalize_embedded_source(fs.read_text(path))
        if source.len() == 0:
            ctx.diagnostics().error("compat-runtime-source: failed to read runtime source: " ++ path)
            return ""
        if source.len() > 500000:
            ctx.diagnostics().error("compat-runtime-source: runtime source too large: " ++ path)
            return ""
        let sym = f"EMBEDDED_RT_{i}"
        out.push_str("let ")
        out.push_str(sym)
        out.push_str(": str = ")
        out.push_str(br_raw_string_literal(source))
        out.push_str("\n")
        if listing.len() > 0:
            listing.push_str("\n")
        listing.push_str(path)
    out.push_str("let EMBEDDED_RT_MODULE_LIST: str = ")
    out.push_str(br_raw_string_literal(listing.to_str()))
    out.push_str("\n\n")
    out.push_str("pub fn embedded_rt_source_data(path: &str) -> str:\n")
    for i in 0..files.len() as i32:
        let path = files.get(i as i64)
        let sym = f"EMBEDDED_RT_{i}"
        out.push_str("    if path == ")
        out.push_str(br_raw_string_literal(path))
        out.push_str(":\n")
        out.push_str("        return ")
        out.push_str(sym)
        out.push_str("\n")
    out.push_str("    return \"\"\n\n")
    out.push_str("pub fn embedded_rt_list_modules_data() -> str:\n")
    out.push_str("    return EMBEDDED_RT_MODULE_LIST\n")
    out.to_str()

pub fn generate_compat_runtime_action(ctx: ActionCtx) -> i32:
    let inputs = ctx.inputs()
    let outputs = ctx.outputs()
    if inputs.len() == 0 or outputs.len() < 4:
        return br_fail(ctx, "requires compat source, primary output, embedded stdlib output, embedded runtime output, and embedded bundles output")

    let fs = ctx.fs()
    let compat_source = inputs.get(0)
    if not fs.exists(compat_source):
        return br_fail(ctx, "missing source: " ++ compat_source)

    let files = br_collect_stdlib_files(ctx)
    if files.len() == 0:
        return br_fail(ctx, "found no stdlib sources")
    let embedded = br_generate_embedded_stdlib(ctx, files)
    if embedded.len() == 0:
        return 1
    let rt_files = br_collect_runtime_files(ctx)
    if rt_files.len() == 0:
        return br_fail(ctx, "found no runtime sources")
    let embedded_rt = br_generate_embedded_runtime(ctx, rt_files)
    if embedded_rt.len() == 0:
        return 1

    let compat_output = outputs.get(0)
    let embedded_output = outputs.get(1)
    let embedded_rt_output = outputs.get(2)
    if fs.mkdir_all(br_dirname(compat_output)) != 0:
        return br_fail(ctx, "could not create output directory: " ++ br_dirname(compat_output))
    if fs.mkdir_all(br_dirname(embedded_output)) != 0:
        return br_fail(ctx, "could not create output directory: " ++ br_dirname(embedded_output))
    if fs.write_text(embedded_output, embedded) != 0:
        return br_fail(ctx, "could not write: " ++ embedded_output)
    if fs.write_text(embedded_rt_output, embedded_rt) != 0:
        return br_fail(ctx, "could not write: " ++ embedded_rt_output)
    // D38: the .wo bundle index; the target's args name the bundles embedded.
    let bundle_names = ctx.args()
    let embedded_bundles_output = outputs.get(3)
    if fs.write_text(embedded_bundles_output, br_generate_embedded_bundles(bundle_names)) != 0:
        return br_fail(ctx, "could not write: " ++ embedded_bundles_output)
    if fs.write_text(compat_output, fs.read_text(compat_source)) != 0:
        return br_fail(ctx, "could not write: " ++ compat_output)
    0
