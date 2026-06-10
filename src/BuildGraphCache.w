// BuildGraphCache -- build state tracking and incrementality.

use BuildGraphModel
use BuildGraphRuntime

extern fn with_str_hash(s: str) -> i64

var build_cache_compiler_fingerprint_ready: i32 = 0
var build_cache_compiler_fingerprint: i64 = 0

pub fn build_cache_state_dir(root: str) -> str:
    root ++ "/out/.build-state"

fn build_cache_state_path(root: str, target_name: str) -> str:
    build_cache_state_dir(root) ++ "/" ++ target_name ++ ".state"

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

fn build_cache_fingerprint_regular_file(path: str) -> i64:
    if build_graph_rt_file_exists(path) == 0:
        return 0
    let contents = build_graph_rt_read_file(path)
    with_str_hash(contents)

fn build_cache_fingerprint_directory(path: str) -> i64:
    let listing = build_graph_rt_list_files(path)
    let files = build_cache_sorted_strings(build_cache_split_lines(listing))
    var combined = "dir\n"
    for i in 0..files.len() as i32:
        let file = files.get(i as i64)
        if build_graph_rt_is_dir(file) == 0:
            combined = combined ++ file ++ ":" ++ f"{build_cache_fingerprint_regular_file(file)}" ++ "\n"
    with_str_hash(combined)

pub fn build_cache_fingerprint_file(path: str) -> i64:
    if build_graph_rt_file_exists(path) == 0:
        return 0
    if build_graph_rt_is_dir(path) != 0:
        return build_cache_fingerprint_directory(path)
    build_cache_fingerprint_regular_file(path)

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

fn build_cache_current_compiler_fingerprint() -> i64:
    if build_cache_compiler_fingerprint_ready != 0:
        return build_cache_compiler_fingerprint
    build_cache_compiler_fingerprint_ready = 1
    let compiler_path = build_cache_resolve_executable_path(build_graph_rt_arg_at(0))
    if compiler_path.len() == 0:
        return 0
    build_cache_compiler_fingerprint = build_cache_fingerprint_file(compiler_path)
    build_cache_compiler_fingerprint

fn build_cache_target_uses_current_compiler(target: BuildGraphTarget) -> bool:
    if target.kind == 0: return true
    if target.kind == 1: return true
    if target.kind == 3: return true
    if target.kind == 4: return true
    if target.kind == 23: return true
    false

fn build_cache_target_has_arg(target: BuildGraphTarget, needle: str) -> bool:
    for i in 0..target.args.len() as i32:
        if target.args.get(i as i64) == needle:
            return true
    false

fn build_cache_target_compiler_path(root: str, target: BuildGraphTarget) -> str:
    for i in 0..target.args.len() as i32:
        let arg = target.args.get(i as i64)
        if arg.starts_with("compiler="):
            let path = arg.slice(9, arg.len())
            if path == "seed":
                return ""
            return root ++ "/" ++ path
    ""

fn build_cache_is_stage_target(target: BuildGraphTarget) -> bool:
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

pub fn build_cache_hash_directory_w_files(root: str, dir: str) -> i64:
    let files = build_cache_list_w_files(root, dir)
    var combined = ""
    for i in 0..files.len() as i32:
        let path = files.get(i as i64)
        let contents = build_graph_rt_read_file(path)
        combined = combined ++ path ++ ":" ++ f"{with_str_hash(contents)}" ++ "\n"
    with_str_hash(combined)

fn build_cache_hash_build_graph_sources(root: str) -> i64:
    var combined = "build.w:" ++ f"{build_cache_fingerprint_file(root ++ "/build.w")}" ++ "\n"
    combined = combined ++ "build:" ++ f"{build_cache_hash_directory_w_files(root, "build")}" ++ "\n"
    combined = combined ++ "std.build:" ++ f"{build_cache_fingerprint_file(root ++ "/lib/std/build.w")}" ++ "\n"
    with_str_hash(combined)

fn build_cache_test_success_manifest(root: str, target: BuildGraphTarget, test_files: Vec[str], test_compiler: str) -> str:
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

pub fn build_cache_record_test_success(root: str, target: BuildGraphTarget, test_files: Vec[str], test_compiler: str) -> void:
    let state_dir = build_cache_state_dir(root)
    let _mkdir = build_graph_rt_mkdir_p(state_dir)
    let marker_path = build_cache_test_success_path(root, target.name)
    let marker = build_cache_test_success_manifest(root, target, test_files, test_compiler)
    let _write = build_graph_rt_write_file(marker_path, marker)

fn build_cache_compute_signature(target: BuildGraphTarget, root: str) -> i64:
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
        sig = sig ++ f":WITH:{build_cache_current_compiler_fingerprint()}"
    if target.kind == 23:
        sig = sig ++ f":BUILD_GRAPH:{build_cache_hash_build_graph_sources(root)}"
    if build_cache_is_stage_target(target):
        let src_hash = build_cache_hash_directory_w_files(root, "src")
        sig = sig ++ f":SRC:{src_hash}"
        let compiler_path = build_cache_target_compiler_path(root, target)
        if compiler_path.len() > 0:
            let compiler_hash = build_cache_fingerprint_file(compiler_path)
            sig = sig ++ f":COMPILER:{compiler_hash}"
    with_str_hash(sig)

fn build_cache_collect_input_paths(root: str, target: BuildGraphTarget) -> Vec[str]:
    var paths: Vec[str] = Vec.new()
    if target.entry.len() > 0:
        paths.push(root ++ "/" ++ target.entry)
    for i in 0..target.inputs.len() as i32:
        let input = target.inputs.get(i as i64)
        if input.len() > 0:
            paths.push(root ++ "/" ++ input)
    paths

fn build_cache_collect_output_paths(root: str, target: BuildGraphTarget) -> Vec[str]:
    var paths: Vec[str] = Vec.new()
    if target.output.len() > 0:
        paths.push(root ++ "/" ++ target.output)
    for i in 0..target.extra_outputs.len() as i32:
        let extra = target.extra_outputs.get(i as i64)
        if extra.len() > 0:
            paths.push(root ++ "/" ++ extra)
    paths

pub fn build_cache_check_fresh(root: str, target: BuildGraphTarget, dep_rebuilt: bool) -> bool:
    if target.name == "prune" or target.name == "prune-apply":
        return false
    if target.name == "last-green" or target.name == "test-green" or target.name == "require-last-green" or target.name == "check-committed-state":
        return false
    if dep_rebuilt:
        return false
    let state_path = build_cache_state_path(root, target.name)
    if build_graph_rt_file_exists(state_path) == 0:
        return false
    let state_text = build_graph_rt_read_file(state_path)
    if state_text.len() == 0:
        return false
    let expected_sig = build_cache_compute_signature(target, root)
    var state_sig: i64 = 0
    var input_hashes: Vec[str] = Vec.new()
    var output_hashes: Vec[str] = Vec.new()
    var line_start = 0
    var i = 0
    while i < state_text.len() as i32:
        let byte = state_text.byte_at(i as i64)
        if byte == 10:
            let line = state_text.slice(line_start as i64, i as i64)
            if line.starts_with("sig:"):
                state_sig = parse_i64_from_str(line.slice(4, line.len()))
            else if line.starts_with("in:"):
                input_hashes.push(line.slice(3, line.len()))
            else if line.starts_with("out:"):
                output_hashes.push(line.slice(4, line.len()))
            line_start = i + 1
        i = i + 1
    if line_start < state_text.len() as i32:
        let line = state_text.slice(line_start as i64, state_text.len())
        if line.starts_with("sig:"):
            state_sig = parse_i64_from_str(line.slice(4, line.len()))
        else if line.starts_with("in:"):
            input_hashes.push(line.slice(3, line.len()))
        else if line.starts_with("out:"):
            output_hashes.push(line.slice(4, line.len()))
    if state_sig != expected_sig:
        return false
    let input_paths = build_cache_collect_input_paths(root, target)
    if input_paths.len() != input_hashes.len():
        return false
    for idx in 0..input_paths.len() as i32:
        let path = input_paths.get(idx as i64)
        let current_hash = build_cache_fingerprint_file(path)
        let stored = input_hashes.get(idx as i64)
        let expected_entry = path ++ ":" ++ f"{current_hash}"
        if stored != expected_entry:
            return false
    let output_paths = build_cache_collect_output_paths(root, target)
    if output_paths.len() != output_hashes.len():
        return false
    for idx in 0..output_paths.len() as i32:
        let path = output_paths.get(idx as i64)
        if build_graph_rt_file_exists(path) == 0:
            return false
        let current_hash = build_cache_fingerprint_file(path)
        let stored = output_hashes.get(idx as i64)
        let expected_entry = path ++ ":" ++ f"{current_hash}"
        if stored != expected_entry:
            return false
    true

pub fn build_cache_record(root: str, target: BuildGraphTarget) -> void:
    let state_dir = build_cache_state_dir(root)
    let _ = build_graph_rt_mkdir_p(state_dir)
    let state_path = build_cache_state_path(root, target.name)
    let sig = build_cache_compute_signature(target, root)
    var content = f"v1\nsig:{sig}\n"
    if build_cache_target_uses_current_compiler(target):
        content = content ++ f"compiler:{build_cache_current_compiler_fingerprint()}\n"
    let input_paths = build_cache_collect_input_paths(root, target)
    for idx in 0..input_paths.len() as i32:
        let path = input_paths.get(idx as i64)
        let hash = build_cache_fingerprint_file(path)
        content = content ++ f"in:{path}:{hash}\n"
    let output_paths = build_cache_collect_output_paths(root, target)
    for idx in 0..output_paths.len() as i32:
        let path = output_paths.get(idx as i64)
        let hash = build_cache_fingerprint_file(path)
        content = content ++ f"out:{path}:{hash}\n"
    let _ = build_graph_rt_write_file(state_path, content)

fn parse_i64_from_str(s: str) -> i64:
    var result: i64 = 0
    var negative = false
    var start = 0
    if s.len() > 0 and s.byte_at(0) == 45:
        negative = true
        start = 1
    var i = start
    while i < s.len() as i32:
        let digit = s.byte_at(i as i64) - 48
        if digit < 0 or digit > 9:
            break
        result = result * 10 + digit as i64
        i = i + 1
    if negative: -result else: result
