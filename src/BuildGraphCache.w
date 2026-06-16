// BuildGraphCache -- build state tracking and incrementality.

use BuildGraphModel
use BuildGraphRuntime
use compiler.TrackedInputs
use std.crypto.sha256

const BUILD_CACHE_S_IFMT: i32 = 61440
const BUILD_CACHE_S_IFDIR: i32 = 16384
const BUILD_CACHE_S_IFREG: i32 = 32768
const BUILD_CACHE_S_IFLNK: i32 = 40960

var build_cache_compiler_fingerprint_ready: i32 = 0
var build_cache_compiler_fingerprint: str = ""

pub fn build_cache_state_dir(root: str) -> str:
    root ++ "/out/.build-state"

fn build_cache_state_path(root: str, target_name: str) -> str:
    build_cache_state_dir(root) ++ "/" ++ target_name ++ ".state"

fn build_cache_effects_path(root: str, target_name: str) -> str:
    build_cache_state_dir(root) ++ "/" ++ target_name ++ ".effects"

fn build_cache_build_effects_path(root: str) -> str:
    build_cache_state_dir(root) ++ "/build.w.effects"

fn build_cache_test_success_path(root: str, target_name: str) -> str:
    build_cache_state_dir(root) ++ "/" ++ target_name ++ ".test-pass"

fn build_cache_project_relative(root: str, path: str) -> str:
    let prefix = root ++ "/"
    if path.starts_with(prefix):
        return path.slice(prefix.len(), path.len())
    path

pub fn build_cache_is_cacheable(kind: i32) -> bool:
    if kind == 0: return true
    if kind == 1: return true
    if kind == 3: return true
    if kind == 4: return true
    if kind == 7: return true
    if kind == 8: return true
    if kind == 10: return true
    if kind == 11: return true
    if kind == 12: return true
    if kind == 13: return true
    if kind == 14: return true
    if kind == 15: return true
    if kind == 16: return true
    if kind == 17: return true
    if kind == 18: return true
    if kind == 22: return true
    if kind == 23: return true
    false

fn build_cache_sha256_text(data: str) -> str:
    var digest: [32]u8 = [0 as u8; 32]
    sha256_hash_str(data, &raw mut digest[0] as *mut u8)
    sha256_hex(&digest[0] as *const u8)

fn build_cache_fingerprint_regular_file(path: str, mode: i32) -> str:
    let exec = if (mode & 0o111) != 0: "x" else: "-"
    build_cache_sha256_text("file\nmode:" ++ f"{mode & 0o777}" ++ "\nexec:" ++ exec ++ "\ncontent:" ++ build_graph_rt_read_file(path))

fn build_cache_fingerprint_directory(path: str, mode: i32) -> str:
    let listing = build_graph_rt_list_files(path)
    let files = build_cache_sorted_strings(build_cache_split_lines(listing))
    var combined = "dir\nmode:" ++ f"{mode & 0o777}" ++ "\n"
    for i in 0..files.len() as i32:
        let file = files.get(i as i64)
        combined = combined ++ file ++ ":" ++ build_cache_fingerprint_file(file) ++ "\n"
    build_cache_sha256_text(combined)

fn build_cache_fingerprint_symlink(path: str, mode: i32) -> str:
    build_cache_sha256_text("symlink\nmode:" ++ f"{mode & 0o777}" ++ "\ntarget:" ++ build_graph_rt_readlink(path))

pub fn build_cache_fingerprint_file(path: str) -> str:
    let mode = build_graph_rt_file_mode(path)
    if mode < 0:
        return build_cache_sha256_text("absent\n")
    let kind = mode & BUILD_CACHE_S_IFMT
    if kind == BUILD_CACHE_S_IFDIR:
        return build_cache_fingerprint_directory(path, mode)
    if kind == BUILD_CACHE_S_IFLNK:
        return build_cache_fingerprint_symlink(path, mode)
    if kind == BUILD_CACHE_S_IFREG:
        return build_cache_fingerprint_regular_file(path, mode)
    build_cache_sha256_text("other\nmode:" ++ f"{mode}" ++ "\n")

fn build_cache_str_contains_byte(text: str, target: i32) -> bool:
    for i in 0..text.len() as i32:
        if text.byte_at(i as i64) == target:
            return true
    false

fn build_cache_resolve_executable_path(argv0: str) -> str:
    if argv0.len() == 0:
        return ""
    if build_graph_rt_file_exists(argv0) != 0:
        return argv0
    if build_cache_str_contains_byte(argv0, 47):
        return ""

    let search_path = build_graph_rt_getenv("PATH")
    if search_path.len() == 0:
        return ""

    var segment_start = 0
    var i = 0
    while i <= search_path.len() as i32:
        let at_end = i == search_path.len() as i32
        let ch = if at_end: 58 else: search_path.byte_at(i as i64)
        if ch == 58:
            let dir = search_path.slice(segment_start as i64, i as i64)
            let candidate = if dir.len() == 0: "./" ++ argv0 else: dir ++ "/" ++ argv0
            if build_graph_rt_file_exists(candidate) != 0:
                return candidate
            segment_start = i + 1
        i = i + 1
    ""

fn build_cache_current_compiler_fingerprint() -> str:
    if build_cache_compiler_fingerprint_ready != 0:
        return build_cache_compiler_fingerprint
    build_cache_compiler_fingerprint_ready = 1
    let compiler_path = build_cache_resolve_executable_path(build_graph_rt_arg_at(0))
    if compiler_path.len() == 0:
        return build_cache_sha256_text("compiler:unresolved\n")
    build_cache_compiler_fingerprint = build_cache_fingerprint_file(compiler_path)
    build_cache_compiler_fingerprint

fn build_cache_target_uses_current_compiler(target: &BuildGraphTarget) -> bool:
    if target.kind == 0: return true
    if target.kind == 1: return true
    if target.kind == 3: return true
    if target.kind == 4: return true
    if target.kind == 23: return true
    false

fn build_cache_target_has_arg(target: &BuildGraphTarget, needle: str) -> bool:
    for i in 0..target.args.len() as i32:
        if target.args.get(i as i64) == needle:
            return true
    false

fn build_cache_target_compiler_path(root: str, target: &BuildGraphTarget) -> str:
    for i in 0..target.args.len() as i32:
        let arg = target.args.get(i as i64)
        if arg.starts_with("compiler="):
            let path = arg.slice(9, arg.len())
            if path == "seed":
                return ""
            return root ++ "/" ++ path
    ""

fn build_cache_is_stage_target(target: &BuildGraphTarget) -> bool:
    if target.kind != 23:
        return false
    var has_compiler = false
    for i in 0..target.args.len() as i32:
        let arg = target.args.get(i as i64)
        if arg == "--no-prelude":
            return false
        if arg.starts_with("compiler="):
            has_compiler = true
    has_compiler

fn build_cache_list_w_files(root: str, dir: str) -> Vec[str]:
    let full_dir = root ++ "/" ++ dir
    let listing = build_graph_rt_list_files(full_dir)
    if listing.len() == 0:
        return Vec.new()
    let all_files = build_cache_split_lines(listing)
    let w_files: Vec[str] = Vec.new()
    for i in 0..all_files.len() as i32:
        let path = all_files.get(i as i64)
        if path.ends_with(".w"):
            w_files.push(path)
    build_cache_sorted_strings(w_files)

fn build_cache_split_lines(text: str) -> Vec[str]:
    let lines: Vec[str] = Vec.new()
    let text_len = text.len() as i32
    var start = 0
    var i = 0
    while i <= text_len:
        var ch = 10
        if i < text_len:
            ch = text.byte_at(i as i64)
        if ch == 10:
            var line = text.slice(start as i64, i as i64)
            if line.len() > 0 and line.byte_at(line.len() as i64 - 1) == 13:
                line = line.slice(0, line.len() - 1)
            if line.len() > 0:
                lines.push(line)
            start = i + 1
        i = i + 1
    lines

fn build_cache_str_compare(a: str, b: str) -> i32:
    let min_len = if a.len() < b.len(): a.len() else: b.len()
    var i = 0
    while i < min_len as i32:
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

fn build_cache_sorted_strings(items: Vec[str]) -> Vec[str]:
    var sorted: Vec[str] = Vec.new()
    for i in 0..items.len() as i32:
        let item = items.get(i as i64)
        var inserted = false
        var out: Vec[str] = Vec.new()
        for j in 0..sorted.len() as i32:
            let existing = sorted.get(j as i64)
            if not inserted and build_cache_str_compare(item, existing) < 0:
                out.push(item)
                inserted = true
            out.push(existing)
        if not inserted:
            out.push(item)
        sorted = out
    sorted

fn build_cache_sorted_unique_strings(items: &Vec[str]) -> Vec[str]:
    var sorted: Vec[str] = Vec.new()
    for i in 0..items.len() as i32:
        sorted = tracked_input_insert_unique(move sorted, items.get(i as i64))
    sorted

fn build_cache_last_colon(text: str) -> i32:
    var last = -1
    for i in 0..text.len() as i32:
        if text.byte_at(i as i64) == 58:
            last = i
    last

fn build_cache_dep_path(root: str, stored_path: str) -> str:
    if stored_path.len() > 0 and stored_path.byte_at(0) == 47:
        return stored_path
    root ++ "/" ++ stored_path

fn build_cache_effect_env_state_line(effect_line: str) -> str:
    if not effect_line.starts_with("env\t"):
        return ""
    var tab_count = 0
    var second_tab = -1
    var third_tab = -1
    for i in 0..effect_line.len() as i32:
        if effect_line.byte_at(i as i64) == 9:
            tab_count = tab_count + 1
            if tab_count == 2:
                second_tab = i
            else if tab_count == 3:
                third_tab = i
                break
    if second_tab < 0 or third_tab < 0:
        return ""
    let name = effect_line.slice((second_tab + 1) as i64, third_tab as i64)
    let hash = effect_line.slice((third_tab + 1) as i64, effect_line.len())
    "env:" ++ name ++ ":" ++ hash

fn build_cache_effects_text(effects: &Vec[str]) -> str:
    let sorted = build_cache_sorted_unique_strings(effects)
    var out = ""
    for i in 0..sorted.len() as i32:
        out = out ++ sorted.get(i as i64) ++ "\n"
    out

pub fn build_cache_hash_directory_w_files(root: str, dir: str) -> str:
    let files = build_cache_list_w_files(root, dir)
    var combined = ""
    for i in 0..files.len() as i32:
        let path = files.get(i as i64)
        combined = combined ++ path ++ ":" ++ build_cache_fingerprint_file(path) ++ "\n"
    build_cache_sha256_text(combined)

fn build_cache_hash_build_graph_sources(root: str) -> str:
    var combined = "build.w:" ++ build_cache_fingerprint_file(root ++ "/build.w") ++ "\n"
    combined = combined ++ "build:" ++ build_cache_hash_directory_w_files(root, "build") ++ "\n"
    combined = combined ++ "std.build:" ++ build_cache_fingerprint_file(root ++ "/lib/std/build.w") ++ "\n"
    build_cache_sha256_text(combined)

fn build_cache_test_success_manifest(root: str, target: &BuildGraphTarget, test_files: &Vec[str], test_compiler: str) -> str:
    var text = "v1\n"
    text = text ++ "target:" ++ target.name ++ "\n"
    text = text ++ f"kind:{target.kind}\n"
    text = text ++ "entry:" ++ target.entry ++ "\n"
    text = text ++ "output:" ++ target.output ++ "\n"
    text = text ++ f"opt:{target.optimize_mode}\n"
    text = text ++ f"target-kind:{target.target_kind}\n"
    for i in 0..target.args.len() as i32:
        text = text ++ "arg:" ++ target.args.get(i as i64) ++ "\n"
    for i in 0..target.defines.len() as i32:
        text = text ++ "define:" ++ target.defines.get(i as i64) ++ "\n"
    for i in 0..target.include_paths.len() as i32:
        text = text ++ "include:" ++ target.include_paths.get(i as i64) ++ "\n"
    for i in 0..target.system_libs.len() as i32:
        text = text ++ "lib:" ++ target.system_libs.get(i as i64) ++ "\n"
    let compiler_rel = build_cache_project_relative(root, test_compiler)
    if compiler_rel.len() > 0:
        text = text ++ "compiler:" ++ compiler_rel ++ "\n"
    else:
        text = text ++ "compiler:\n"
    let rel_files: Vec[str] = Vec.new()
    for i in 0..test_files.len() as i32:
        rel_files.push(build_cache_project_relative(root, test_files.get(i as i64)))
    let sorted = build_cache_sorted_strings(rel_files)
    for i in 0..sorted.len() as i32:
        let path = sorted.get(i as i64)
        text = text ++ "file:" ++ path ++ "\n"
    text

pub fn build_cache_record_test_success(root: str, target: &BuildGraphTarget, test_files: &Vec[str], test_compiler: str) -> Unit:
    let state_dir = build_cache_state_dir(root)
    let _mkdir = build_graph_rt_mkdir_p(state_dir)
    let marker_path = build_cache_test_success_path(root, target.name)
    let marker = build_cache_test_success_manifest(root, target, test_files, test_compiler)
    let _write = build_graph_rt_write_file(marker_path, marker)

fn build_cache_compute_signature(target: &BuildGraphTarget, root: str) -> str:
    var sig = f"{target.kind}:{target.name}:{target.entry}:{target.output}"
    sig = sig ++ f":{target.optimize_mode}:{target.target_kind}"
    for i in 0..target.args.len() as i32:
        sig = sig ++ ":" ++ target.args.get(i as i64)
    for i in 0..target.defines.len() as i32:
        sig = sig ++ ":D:" ++ target.defines.get(i as i64)
    for i in 0..target.include_paths.len() as i32:
        sig = sig ++ ":I:" ++ target.include_paths.get(i as i64)
    for i in 0..target.system_libs.len() as i32:
        sig = sig ++ ":L:" ++ target.system_libs.get(i as i64)
    if build_cache_target_uses_current_compiler(target):
        sig = sig ++ ":WITH:" ++ build_cache_current_compiler_fingerprint()
    if target.kind == 23:
        sig = sig ++ ":BUILD_GRAPH:" ++ build_cache_hash_build_graph_sources(root)
    if build_cache_is_stage_target(target):
        let src_hash = build_cache_hash_directory_w_files(root, "src")
        sig = sig ++ ":SRC:" ++ src_hash
        let compiler_path = build_cache_target_compiler_path(root, target)
        if compiler_path.len() > 0:
            let compiler_hash = build_cache_fingerprint_file(compiler_path)
            sig = sig ++ ":COMPILER:" ++ compiler_hash
    build_cache_sha256_text(sig)

fn build_cache_collect_input_paths(root: str, target: &BuildGraphTarget) -> Vec[str]:
    var paths: Vec[str] = Vec.new()
    if target.entry.len() > 0:
        paths.push(root ++ "/" ++ target.entry)
    for i in 0..target.inputs.len() as i32:
        let input = target.inputs.get(i as i64)
        if input.len() > 0:
            paths.push(root ++ "/" ++ input)
    paths

fn build_cache_collect_output_paths(root: str, target: &BuildGraphTarget) -> Vec[str]:
    var paths: Vec[str] = Vec.new()
    if target.output.len() > 0:
        paths.push(root ++ "/" ++ target.output)
    for i in 0..target.extra_outputs.len() as i32:
        let extra = target.extra_outputs.get(i as i64)
        if extra.len() > 0:
            paths.push(root ++ "/" ++ extra)
    paths

pub fn build_cache_freshness_reason(root: str, target: &BuildGraphTarget, dep_rebuilt: bool) -> str:
    if not build_cache_is_cacheable(target.kind):
        return "not cacheable"
    if target.name == "prune" or target.name == "prune-apply":
        return "stale: target is always run"
    if target.name == "last-green" or target.name == "test-green" or target.name == "require-last-green" or target.name == "check-committed-state" or target.name == "print-version":
        return "stale: target is always run"
    if dep_rebuilt:
        return "stale: dependency rebuilt"
    let state_path = build_cache_state_path(root, target.name)
    if build_graph_rt_file_exists(state_path) == 0:
        return "stale: no cache state"
    let state_text = build_graph_rt_read_file(state_path)
    if state_text.len() == 0:
        return "stale: empty cache state"
    let expected_sig = build_cache_compute_signature(target, root)
    var state_sig = ""
    var effect_hash = ""
    var input_hashes: Vec[str] = Vec.new()
    var dep_hashes: Vec[str] = Vec.new()
    var env_hashes: Vec[str] = Vec.new()
    var output_hashes: Vec[str] = Vec.new()
    var saw_v2 = false
    var line_start = 0
    var i = 0
    while i < state_text.len() as i32:
        let byte = state_text.byte_at(i as i64)
        if byte == 10:
            let line = state_text.slice(line_start as i64, i as i64)
            if line == "v2":
                saw_v2 = true
            else if line.starts_with("sig:"):
                state_sig = line.slice(4, line.len())
            else if line.starts_with("effects:"):
                effect_hash = line.slice(8, line.len())
            else if line.starts_with("in:"):
                input_hashes.push(line.slice(3, line.len()))
            else if line.starts_with("dep:"):
                dep_hashes.push(line.slice(4, line.len()))
            else if line.starts_with("env:"):
                env_hashes.push(line.slice(4, line.len()))
            else if line.starts_with("out:"):
                output_hashes.push(line.slice(4, line.len()))
            line_start = i + 1
        i = i + 1
    if line_start < state_text.len() as i32:
        let line = state_text.slice(line_start as i64, state_text.len())
        if line == "v2":
            saw_v2 = true
        else if line.starts_with("sig:"):
            state_sig = line.slice(4, line.len())
        else if line.starts_with("effects:"):
            effect_hash = line.slice(8, line.len())
        else if line.starts_with("in:"):
            input_hashes.push(line.slice(3, line.len()))
        else if line.starts_with("dep:"):
            dep_hashes.push(line.slice(4, line.len()))
        else if line.starts_with("env:"):
            env_hashes.push(line.slice(4, line.len()))
        else if line.starts_with("out:"):
            output_hashes.push(line.slice(4, line.len()))
    if not saw_v2:
        return "stale: cache state version changed"
    if state_sig != expected_sig:
        return "stale: action signature changed"
    let input_paths = build_cache_collect_input_paths(root, target)
    if input_paths.len() != input_hashes.len():
        return "stale: input set changed"
    for idx in 0..input_paths.len() as i32:
        let path = input_paths.get(idx as i64)
        let current_hash = build_cache_fingerprint_file(path)
        let stored = input_hashes.get(idx as i64)
        let expected_entry = path ++ ":" ++ current_hash
        if stored != expected_entry:
            return "stale: input changed: " ++ build_cache_project_relative(root, path)
    for idx in 0..dep_hashes.len() as i32:
        let stored = dep_hashes.get(idx as i64)
        let split = build_cache_last_colon(stored)
        if split < 0:
            return "stale: malformed dependency state"
        let stored_path = stored.slice(0, split as i64)
        let path = build_cache_dep_path(root, stored_path)
        let current_hash = build_cache_fingerprint_file(path)
        let expected_entry = stored_path ++ ":" ++ current_hash
        if stored != expected_entry:
            return "stale: discovered dependency changed: " ++ stored_path
    for idx in 0..env_hashes.len() as i32:
        let stored = env_hashes.get(idx as i64)
        let split = build_cache_last_colon(stored)
        if split < 0:
            return "stale: malformed environment state"
        let name = stored.slice(0, split as i64)
        let current_hash = build_cache_sha256_text(build_graph_rt_getenv(name))
        let expected_entry = name ++ ":" ++ current_hash
        if stored != expected_entry:
            return "stale: environment variable changed: " ++ name
    if effect_hash.len() > 0:
        let effects_path = build_cache_effects_path(root, target.name)
        if build_graph_rt_file_exists(effects_path) == 0:
            return "stale: effect log missing"
        if build_cache_sha256_text(build_graph_rt_read_file(effects_path)) != effect_hash:
            return "stale: effect log changed"
    let output_paths = build_cache_collect_output_paths(root, target)
    if output_paths.len() != output_hashes.len():
        return "stale: output set changed"
    for idx in 0..output_paths.len() as i32:
        let path = output_paths.get(idx as i64)
        if build_graph_rt_file_exists(path) == 0:
            return "stale: output missing: " ++ build_cache_project_relative(root, path)
        let current_hash = build_cache_fingerprint_file(path)
        let stored = output_hashes.get(idx as i64)
        let expected_entry = path ++ ":" ++ current_hash
        if stored != expected_entry:
            return "stale: output changed: " ++ build_cache_project_relative(root, path)
    "fresh"

pub fn build_cache_check_fresh(root: str, target: &BuildGraphTarget, dep_rebuilt: bool) -> bool:
    build_cache_freshness_reason(root, target, dep_rebuilt) == "fresh"

pub fn build_cache_record(root: str, target: &BuildGraphTarget, discovered_deps: Vec[str], effects: Vec[str]) -> Unit:
    let state_dir = build_cache_state_dir(root)
    let _ = build_graph_rt_mkdir_p(state_dir)
    let state_path = build_cache_state_path(root, target.name)
    let sig = build_cache_compute_signature(target, root)
    var content = "v2\nsig:" ++ sig ++ "\n"
    if build_cache_target_uses_current_compiler(target):
        content = content ++ "compiler:" ++ build_cache_current_compiler_fingerprint() ++ "\n"
    let input_paths = build_cache_collect_input_paths(root, target)
    for idx in 0..input_paths.len() as i32:
        let path = input_paths.get(idx as i64)
        let hash = build_cache_fingerprint_file(path)
        content = content ++ "in:" ++ path ++ ":" ++ hash ++ "\n"
    let dep_paths = build_cache_sorted_unique_strings(discovered_deps)
    for idx in 0..dep_paths.len() as i32:
        let path = dep_paths.get(idx as i64)
        let hash = build_cache_fingerprint_file(path)
        let rel_path = build_cache_project_relative(root, path)
        content = content ++ "dep:" ++ rel_path ++ ":" ++ hash ++ "\n"
    let effects_text = build_cache_effects_text(effects)
    if effects_text.len() > 0:
        let effects_path = build_cache_effects_path(root, target.name)
        let _write_effects = build_graph_rt_write_file(effects_path, effects_text)
        content = content ++ "effects:" ++ build_cache_sha256_text(effects_text) ++ "\n"
        let sorted_effects = build_cache_sorted_unique_strings(effects)
        for idx in 0..sorted_effects.len() as i32:
            let env_line = build_cache_effect_env_state_line(sorted_effects.get(idx as i64))
            if env_line.len() > 0:
                content = content ++ env_line ++ "\n"
    else:
        let _remove_effects = build_graph_rt_remove_file(build_cache_effects_path(root, target.name))
    let output_paths = build_cache_collect_output_paths(root, target)
    for idx in 0..output_paths.len() as i32:
        let path = output_paths.get(idx as i64)
        let hash = build_cache_fingerprint_file(path)
        content = content ++ "out:" ++ path ++ ":" ++ hash ++ "\n"
    let _ = build_graph_rt_write_file(state_path, content)

pub fn build_cache_record_build_effects(root: str, effects: Vec[str]) -> Unit:
    let state_dir = build_cache_state_dir(root)
    let _ = build_graph_rt_mkdir_p(state_dir)
    let effects_text = build_cache_effects_text(effects)
    let path = build_cache_build_effects_path(root)
    if effects_text.len() > 0:
        let _write = build_graph_rt_write_file(path, effects_text)
    else:
        let _remove = build_graph_rt_remove_file(path)

pub fn build_cache_print_effects(root: str, graph: &BuildGraph, target_filter: str) -> i32:
    if target_filter.len() == 0 or target_filter == "build.w":
        build_graph_rt_write("target build.w\n")
        build_graph_rt_write("  capabilities: BuildCtx ProjectInfo Diagnostics SourceEmitter ToolFs ProcessRunner Workspace\n")
        let build_effects_path = build_cache_build_effects_path(root)
        if build_graph_rt_file_exists(build_effects_path) == 0:
            build_graph_rt_write("  reproducible: yes\n")
            build_graph_rt_write("  effects: none\n")
        else:
            let build_effects = build_graph_rt_read_file(build_effects_path)
            build_graph_rt_write("  reproducible: yes\n")
            if build_effects.len() == 0:
                build_graph_rt_write("  effects: none\n")
            else:
                build_graph_rt_write(build_effects)
    for ti in 0..graph.targets.len() as i32:
        let target = graph.targets.get(ti as i64)
        if target_filter.len() > 0 and target.name != target_filter:
            continue
        build_graph_rt_write("target " ++ target.name ++ "\n")
        if target.kind == 23:
            build_graph_rt_write("  capabilities: ActionCtx ProjectInfo Diagnostics ToolFs ProcessRunner Workspace\n")
        else:
            build_graph_rt_write("  capabilities: none\n")
        let effects_path = build_cache_effects_path(root, target.name)
        if build_graph_rt_file_exists(effects_path) == 0:
            build_graph_rt_write("  reproducible: yes\n")
            build_graph_rt_write("  effects: none\n")
            continue
        let effects = build_graph_rt_read_file(effects_path)
        if effects.len() == 0:
            build_graph_rt_write("  reproducible: yes\n")
            build_graph_rt_write("  effects: none\n")
        else:
            build_graph_rt_write("  reproducible: yes\n")
            build_graph_rt_write(effects)
    0
