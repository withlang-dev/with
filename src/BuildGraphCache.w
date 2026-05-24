// BuildGraphCache -- build state tracking and incrementality.

use BuildGraphModel
use BuildGraphRuntime

extern fn with_str_hash(s: str) -> i64

pub fn build_cache_state_dir(root: str) -> str:
    root ++ "/out/.build-state"

fn build_cache_state_path(root: str, target_name: str) -> str:
    build_cache_state_dir(root) ++ "/" ++ target_name ++ ".state"

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

pub fn build_cache_fingerprint_file(path: str) -> i64:
    if build_graph_rt_file_exists(path) == 0:
        return 0
    let contents = build_graph_rt_read_file(path)
    with_str_hash(contents)

fn build_cache_compute_signature(target: BuildGraphTarget) -> i64:
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
    if dep_rebuilt:
        return false
    let state_path = build_cache_state_path(root, target.name)
    if build_graph_rt_file_exists(state_path) == 0:
        return false
    let state_text = build_graph_rt_read_file(state_path)
    if state_text.len() == 0:
        return false
    let expected_sig = build_cache_compute_signature(target)
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

pub fn build_cache_record(root: str, target: BuildGraphTarget):
    let state_dir = build_cache_state_dir(root)
    let _ = build_graph_rt_mkdir_p(state_dir)
    let state_path = build_cache_state_path(root, target.name)
    let sig = build_cache_compute_signature(target)
    var content = f"v1\nsig:{sig}\n"
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
