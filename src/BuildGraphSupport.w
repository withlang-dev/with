// BuildGraphSupport -- path and argv helpers shared by build graph execution.

use Resolve
use BuildGraphModel
use BuildGraphRuntime
use compiler.Runtime

extern fn with_str_clone_ref(s: &str) -> str

pub fn build_graph_output_path(root: &str, target: &BuildGraphTarget, output_path: &str, target_count: i32) -> str:
    if output_path.len() > 0:
        if target_count != 1:
            return ""
        return runtime_str_clone(output_path)
    if target.output.len() > 0:
        return build_graph_resolve_project_path(root, target.output)
    resolve_join(resolve_join(root, "out/bin"), target.name)

pub fn build_graph_library_output_path(root: &str, target: &BuildGraphTarget, output_path: &str, target_count: i32) -> str:
    if output_path.len() > 0:
        if target_count != 1:
            return ""
        return runtime_str_clone(output_path)
    if target.output.len() > 0:
        return build_graph_resolve_project_path(root, target.output)
    resolve_join(resolve_join(root, "out/lib"), "lib" ++ target.name ++ ".a")

pub fn build_graph_object_output_path(root: &str, target: &BuildGraphTarget, output_path: &str, target_count: i32) -> str:
    if output_path.len() > 0:
        if target_count != 1:
            return ""
        return runtime_str_clone(output_path)
    if target.output.len() > 0:
        return build_graph_resolve_project_path(root, target.output)
    resolve_join(resolve_join(root, "out/obj"), target.name ++ ".o")

pub fn build_graph_resolve_project_path(root: &str, path: &str) -> str:
    if path.len() > 0 and path.byte_at(0) == 47:
        return with_str_clone_ref(path)
    resolve_join(root, path)

pub fn build_graph_resolve_paths(root: &str, paths: &Vec[str]) -> Vec[str]:
    let out: Vec[str] = Vec.new()
    for i in 0..paths.len() as i32:
        out.push(build_graph_resolve_project_path(root, paths.get(i as i64)))
    out

pub fn build_graph_clone_strings(values: &Vec[str]) -> Vec[str]:
    let out: Vec[str] = Vec.new()
    for i in 0..values.len() as i32:
        out.push(runtime_str_clone(values.get(i as i64)))
    out

pub fn build_graph_dirname(path: &str) -> str:
    var last_slash = -1
    for i in 0..path.len() as i32:
        if path.byte_at(i as i64) == 47:
            last_slash = i
    if last_slash < 0:
        return "."
    path.slice(0, last_slash as i64)

pub fn build_graph_path_basename(path: &str) -> str:
    let dir = build_graph_dirname(path)
    if dir == ".":
        return with_str_clone_ref(path)
    path.slice((dir.len() + 1) as i64, path.len())

pub fn build_graph_path_has_glob(path: &str) -> bool:
    path.contains("*")

pub fn build_graph_single_star_pattern_matches(pattern: &str, name: &str) -> bool:
    var star = -1
    for i in 0..pattern.len() as i32:
        if pattern.byte_at(i as i64) == 42:
            if star >= 0:
                return false
            star = i
    if star < 0:
        return pattern == name
    let prefix = pattern.slice(0, star as i64)
    let suffix = pattern.slice((star + 1) as i64, pattern.len())
    if name.len() < prefix.len() + suffix.len():
        return false
    if prefix.len() > 0 and name.slice(0, prefix.len()) != prefix:
        return false
    if suffix.len() > 0:
        let suffix_start = name.len() - suffix.len()
        if name.slice(suffix_start, name.len()) != suffix:
            return false
    true

pub fn build_graph_path_for_child_process(root: &str, path: &str) -> str:
    var normalized_root = with_str_clone_ref(root)
    while normalized_root.len() > 1 and normalized_root.ends_with("/"):
        normalized_root = normalized_root.slice(0, normalized_root.len() - 1)
    if normalized_root.ends_with("/."):
        normalized_root = normalized_root.slice(0, normalized_root.len() - 2)
    let dot_prefix = normalized_root ++ "/./"
    if path.starts_with(dot_prefix):
        return path.slice(dot_prefix.len(), path.len())
    let prefix = normalized_root ++ "/"
    if path.starts_with(prefix):
        return path.slice(prefix.len(), path.len())
    with_str_clone_ref(path)

pub fn build_graph_generated_path_valid(path: &str) -> bool:
    if path.len() == 0:
        return false
    if path.byte_at(0) == 47:
        return false
    if path.contains(".."):
        return false
    for i in 0..path.len() as i32:
        let ch = path.byte_at(i as i64)
        if ch == 10 or ch == 13 or ch == 9:
            return false
    true

pub fn build_graph_manifest_relative_path_valid(path: &str) -> bool:
    if path.len() == 0:
        return false
    if path.byte_at(0) == 47:
        return false
    if path.contains(".."):
        return false
    for i in 0..path.len() as i32:
        let ch = path.byte_at(i as i64)
        if ch == 0 or ch == 10 or ch == 13 or ch == 9:
            return false
    true

pub fn build_graph_define_valid(define: &str) -> bool:
    if define.len() == 0:
        return false
    for i in 0..define.len() as i32:
        let ch = define.byte_at(i as i64)
        if ch == 10 or ch == 13:
            return false
    true

pub fn build_graph_process_arg_valid(arg: &str) -> bool:
    for i in 0..arg.len() as i32:
        if arg.byte_at(i as i64) == 0:
            return false
    true

pub fn build_graph_path_project_contained(path: &str) -> bool:
    if path.len() == 0:
        return true
    if path.byte_at(0) == 47:
        return false
    if path.contains(".."):
        return false
    if path.starts_with("$"):
        return false
    for i in 0..path.len() as i32:
        let ch = path.byte_at(i as i64)
        if ch == 0 or ch == 10 or ch == 13 or ch == 9:
            return false
    true

pub fn build_graph_path_is_install_dest(path: &str) -> bool:
    path.starts_with("$HOME/") or path.starts_with("$INSTALL_BINDIR/") or path.starts_with("$INSTALL_LIBDIR/")

pub fn build_graph_validate_target_containment(target: &BuildGraphTarget) -> i32:
    let kind = target.kind
    let is_install = kind == 8
    let is_promote = kind == 20
    let is_clean = kind == 21
    if is_clean:
        return 0
    if target.output.len() > 0:
        if is_install:
            if not build_graph_path_is_install_dest(target.output) and not build_graph_path_project_contained(target.output):
                build_graph_rt_eprint("error: install target '" ++ target.name ++ "' output escapes project root without install prefix: " ++ target.output)
                return 1
        else if is_promote:
            if not build_graph_path_project_contained(target.output):
                build_graph_rt_eprint("error: promote target '" ++ target.name ++ "' output escapes project root: " ++ target.output)
                return 1
        else:
            if not build_graph_path_project_contained(target.output):
                build_graph_rt_eprint("error: target '" ++ target.name ++ "' output escapes project root: " ++ target.output)
                return 1
    let is_command = kind == 7
    let is_corpus = kind == 19
    let is_action = kind == 23
    let entry_is_executable = is_command or is_corpus
    if target.entry.len() > 0 and not is_install and not entry_is_executable and not is_action:
        if not build_graph_path_project_contained(target.entry):
            build_graph_rt_eprint("error: target '" ++ target.name ++ "' entry escapes project root: " ++ target.entry)
            return 1
    for oi in 0..target.extra_outputs.len() as i32:
        let extra = target.extra_outputs.get(oi as i64)
        if not build_graph_path_project_contained(extra):
            build_graph_rt_eprint("error: target '" ++ target.name ++ "' extra_output escapes project root: " ++ extra)
            return 1
    0

pub fn build_graph_argv_append(argv_blob: &str, arg: &str) -> str:
    argv_blob ++ arg ++ "\0"

pub fn build_graph_exec_argv(target: &BuildGraphTarget, operation_name: &str, argv_blob: &str) -> i32:
    let rc = build_graph_rt_exec_argv(argv_blob)
    if rc != 0:
        build_graph_rt_eprint("error: " ++ operation_name ++ " target '" ++ target.name ++ f"' failed with exit code {rc}")
        return rc
    0

pub fn build_graph_validate_process_args(target: &BuildGraphTarget) -> i32:
    if not build_graph_process_arg_valid(target.entry):
        build_graph_rt_eprint("error: target '" ++ target.name ++ "' field 'entry' contains a NUL byte: " ++ target.entry)
        return 1
    if not build_graph_process_arg_valid(target.output):
        build_graph_rt_eprint("error: target '" ++ target.name ++ "' field 'output' contains a NUL byte: " ++ target.output)
        return 1
    for ii in 0..target.inputs.len() as i32:
        if not build_graph_process_arg_valid(target.inputs.get(ii as i64)):
            build_graph_rt_eprint("error: target '" ++ target.name ++ f"' field 'input[{ii}]' contains a NUL byte")
            return 1
    for ai in 0..target.args.len() as i32:
        if not build_graph_process_arg_valid(target.args.get(ai as i64)):
            build_graph_rt_eprint("error: target '" ++ target.name ++ f"' field 'arg[{ai}]' contains a NUL byte")
            return 1
    0

fn build_graph_split_nonempty_lines(text: &str) -> Vec[str]:
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

fn build_graph_str_compare(a: &str, b: &str) -> i32:
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

pub fn build_graph_sorted_strings(items: &Vec[str]) -> Vec[str]:
    var sorted: Vec[str] = Vec.new()
    for i in 0..items.len() as i32:
        let item = items.get(i as i64)
        var inserted = false
        var out: Vec[str] = Vec.new()
        for j in 0..sorted.len() as i32:
            let existing = sorted.get(j as i64)
            if not inserted and build_graph_str_compare(item, existing) < 0:
                out.push(with_str_clone_ref(item))
                inserted = true
            out.push(with_str_clone_ref(existing))
        if not inserted:
            out.push(with_str_clone_ref(item))
        sorted = out
    sorted

pub fn collect_test_files(target_dir: &str) -> Vec[str]:
    let listing = build_graph_rt_list_files(target_dir)
    if listing.len() == 0:
        return Vec.new()
    let all_files = build_graph_split_nonempty_lines(listing)
    let w_files: Vec[str] = Vec.new()
    for i in 0..all_files.len() as i32:
        let path = all_files.get(i as i64)
        if path.ends_with(".w"):
            w_files.push(with_str_clone_ref(path))
    build_graph_sorted_strings(w_files)

pub fn build_graph_time_fmt(ns: i64) -> str:
    let tenths = ns / 100000000
    f"{tenths / 10}.{tenths % 10}s"

fn build_graph_time_picked(picked: &Vec[i64], idx: i64) -> bool:
    for i in 0..picked.len() as i32:
        if picked.get(i as i64) == idx:
            return true
    false

fn build_graph_rss_fmt(bytes: i64) -> str:
    if bytes <= 0:
        return "0M"
    f"{(bytes + 524288) / 1048576}M"

// Per-invocation wall-time + peak-RSS record: chronological TSV beside the
// cache state (the dir build_cache_state_dir names), plus a slowest-first
// stderr summary with the RSS high-water target (#679/#702 — the 8 GB
// budget needs per-target attribution, like wall time got in c3de4c0b).
// Pooled children report exact wait4 rusage; in-process targets report the
// orchestrator's high-water DELTA around the target (0 when it stayed under
// the existing mark — attribution, not absolute footprint).
// Durations and sizes must never enter hashed build inputs or artifacts.
pub fn build_graph_times_report(root: &str, names: &Vec[str], ns_list: &Vec[i64], rss_list: &Vec[i64], total_ns: i64) -> Unit:
    if names.len() == 0:
        return
    var text = "target\tseconds\tpeak_rss\n"
    for i in 0..names.len() as i32:
        let rss = if i < rss_list.len() as i32: rss_list.get(i as i64) else: 0
        text = text ++ names.get(i as i64) ++ "\t" ++ build_graph_time_fmt(ns_list.get(i as i64)) ++ "\t" ++ build_graph_rss_fmt(rss) ++ "\n"
    text = text ++ "TOTAL\t" ++ build_graph_time_fmt(total_ns) ++ "\t" ++ build_graph_rss_fmt(build_graph_rt_self_maxrss()) ++ "\n"
    let state_dir = resolve_join(root, "out/.build-state")
    let _mkdir = build_graph_rt_mkdir_p(state_dir)
    let _write = build_graph_rt_write_file(resolve_join(state_dir, "build-times.tsv"), text)
    var summary = "[times] total " ++ build_graph_time_fmt(total_ns) ++ f" across {names.len() as i32} executed; slowest:"
    let picked: Vec[i64] = Vec.new()
    while picked.len() < 5 and picked.len() < names.len():
        var best: i64 = -1
        for i in 0..names.len() as i32:
            if not build_graph_time_picked(&picked, i as i64):
                if best < 0 or ns_list.get(i as i64) > ns_list.get(best):
                    best = i as i64
        picked.push(best)
        summary = summary ++ " " ++ names.get(best) ++ " " ++ build_graph_time_fmt(ns_list.get(best))
    var rss_best: i64 = -1
    for i in 0..rss_list.len() as i32:
        if rss_best < 0 or rss_list.get(i as i64) > rss_list.get(rss_best):
            rss_best = i as i64
    if rss_best >= 0 and rss_best < names.len() as i32 and rss_list.get(rss_best) > 0:
        summary = summary ++ "; peak rss " ++ build_graph_rss_fmt(rss_list.get(rss_best)) ++ " (" ++ names.get(rss_best) ++ ")"
    build_graph_rt_eprint(summary ++ " (out/.build-state/build-times.tsv)")
