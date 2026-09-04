// BuildGraphCache -- build state tracking and incrementality.

use BuildGraphModel
use BuildGraphRuntime
use BuildGraphSupport
use compiler.TrackedInputs
use std.crypto.sha256
use std.collections.HashMap

extern fn with_str_clone_ref(s: &str) -> str
extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut u8) -> Unit

const BUILD_CACHE_S_IFMT: i32 = 61440
const BUILD_CACHE_S_IFDIR: i32 = 16384
const BUILD_CACHE_S_IFREG: i32 = 32768
const BUILD_CACHE_S_IFLNK: i32 = 40960

var build_cache_compiler_fingerprint_ready: i32 = 0
var build_cache_compiler_fingerprint: str = ""

// #702: per-run file-fingerprint memo. Freshness verification re-fingerprints
// each target's inputs, outputs, and dep outputs, so one battery run re-reads
// the same ~100MB stage binaries dozens of times — pre-#691 every read buffer
// is permanent, which alone walked the runner into the 32GiB ceiling. Files
// only change when a target executes, so the memo is valid across any
// execution-free window; build_cache_forget_fingerprints clears it whenever a
// target actually runs (coarse, provably safe — fully-cached runs keep the
// entire win).
var build_cache_fp_memo: HashMap[str, str] = HashMap.new()

pub fn build_cache_forget_fingerprints() -> Unit:
    build_cache_fp_memo = HashMap.new()

pub fn build_cache_state_dir(root: &str) -> str:
    root ++ "/out/.build-state"

fn build_cache_state_path(root: &str, target_name: &str) -> str:
    build_cache_state_dir(root) ++ "/" ++ target_name ++ ".state"

fn build_cache_effects_path(root: &str, target_name: &str) -> str:
    build_cache_state_dir(root) ++ "/" ++ target_name ++ ".effects"

fn build_cache_build_effects_path(root: &str) -> str:
    build_cache_state_dir(root) ++ "/build.w.effects"

fn build_cache_test_success_path(root: &str, target_name: &str) -> str:
    build_cache_state_dir(root) ++ "/" ++ target_name ++ ".test-pass"

fn build_cache_project_relative(root: &str, path: &str) -> str:
    let prefix = root ++ "/"
    if path.starts_with(prefix):
        return path.slice(prefix.len(), path.len())
    with_str_clone_ref(path)

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
    // 19 (RunCorpusTest): the verdict is a function of the entry binary
    // (hashed as an input) plus dep-rebuilt propagation — selfcheck re-runs
    // when stage2 changed, not on every invocation that walks past it
    // (#702: it was an 86s always-run tax on any dep chain touching it).
    if kind == 19: return true
    if kind == 22: return true
    if kind == 23: return true
    false

fn build_cache_sha256_text(data: &str) -> str:
    var digest: [32]u8 = [0 as u8; 32]
    sha256_hash_str(data, &raw mut digest[0] as *mut u8)
    sha256_hex(&digest[0] as *const u8)

// Digest-identical to hashing framing ++ payload, but the payload (often a
// 100MB binary) never enters a `++` chain — each intermediate of that chain
// is a leaked copy of the whole payload pre-#691, and the battery hashes
// these files once per target check. One explicit alloc/free instead;
// implemented on sha256's single-shot API because compiler source compiles
// against the seed's embedded stdlib and cannot use a same-change stdlib fn.
fn build_cache_sha256_framed(framing: &str, payload: &str) -> str:
    var digest: [32]u8 = [0 as u8; 32]
    unsafe:
        let total = framing.len() + payload.len()
        let buf = with_alloc(total)
        var i: i64 = 0
        while i < framing.len():
            *((buf as i64 + i) as *mut u8) = framing[i] as u8
            i = i + 1
        var j: i64 = 0
        while j < payload.len():
            *((buf as i64 + framing.len() + j) as *mut u8) = payload[j] as u8
            j = j + 1
        sha256_hash(buf as *const u8, total as i32, &raw mut digest[0] as *mut u8)
        with_free(buf)
    sha256_hex(&digest[0] as *const u8)

fn build_cache_fingerprint_regular_file(path: &str, mode: i32) -> str:
    let exec = if (mode & 0o111) != 0: "x" else: "-"
    build_cache_sha256_framed("file\nmode:" ++ f"{mode & 0o777}" ++ "\nexec:" ++ exec ++ "\ncontent:", build_graph_rt_read_file(path))

fn build_cache_fingerprint_directory(path: &str, mode: i32) -> str:
    let listing = build_graph_rt_list_files(path)
    let files = build_cache_sorted_strings(build_cache_split_lines(listing))
    var combined = "dir\nmode:" ++ f"{mode & 0o777}" ++ "\n"
    for i in 0..files.len() as i32:
        let file = files[i]
        combined = combined ++ file ++ ":" ++ build_cache_fingerprint_file(file) ++ "\n"
    build_cache_sha256_text(combined)

fn build_cache_fingerprint_symlink(path: &str, mode: i32) -> str:
    build_cache_sha256_text("symlink\nmode:" ++ f"{mode & 0o777}" ++ "\ntarget:" ++ build_graph_rt_readlink(path))

pub fn build_cache_fingerprint_file(path: &str) -> str:
    let memoized = build_cache_fp_memo.get(path)
    if memoized.is_some():
        return with_str_clone_ref(memoized.unwrap())
    let mode = build_graph_rt_file_mode(path)
    if mode < 0:
        return build_cache_sha256_text("absent\n")
    let kind = mode & BUILD_CACHE_S_IFMT
    var fp = ""
    if kind == BUILD_CACHE_S_IFDIR:
        fp = build_cache_fingerprint_directory(path, mode)
    else: if kind == BUILD_CACHE_S_IFLNK:
        fp = build_cache_fingerprint_symlink(path, mode)
    else: if kind == BUILD_CACHE_S_IFREG:
        fp = build_cache_fingerprint_regular_file(path, mode)
    else:
        fp = build_cache_sha256_text("other\nmode:" ++ f"{mode}" ++ "\n")
    build_cache_fp_memo.insert(with_str_clone_ref(path), with_str_clone_ref(fp))
    fp

fn build_cache_str_contains_byte(text: &str, target: i32) -> bool:
    for i in 0..text.len() as i32:
        if text[i] == target:
            return true
    false

fn build_cache_resolve_executable_path(argv0: &str) -> str:
    if argv0.len() == 0:
        return ""
    if build_graph_rt_file_exists(argv0) != 0:
        return with_str_clone_ref(argv0)
    if build_cache_str_contains_byte(argv0, 47):
        return ""

    let search_path = build_graph_rt_getenv("PATH")
    if search_path.len() == 0:
        return ""

    var segment_start = 0
    var i = 0
    while i <= search_path.len() as i32:
        let at_end = i == search_path.len() as i32
        let ch = if at_end: 58 else: search_path[i]
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

fn build_cache_target_has_arg(target: &BuildGraphTarget, needle: &str) -> bool:
    for i in 0..target.args.len() as i32:
        if target.args[i] == needle:
            return true
    false

fn build_cache_target_compiler_path(root: &str, target: &BuildGraphTarget) -> str:
    for i in 0..target.args.len() as i32:
        let arg = target.args[i]
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
        let arg = target.args[i]
        if arg == "--no-prelude":
            return false
        if arg.starts_with("compiler="):
            has_compiler = true
    has_compiler

fn build_cache_list_w_files(root: &str, dir: &str) -> Vec[str]:
    let full_dir = root ++ "/" ++ dir
    let listing = build_graph_rt_list_files(full_dir)
    if listing.len() == 0:
        return Vec.new()
    let all_files = build_cache_split_lines(listing)
    let w_files: Vec[str] = Vec.new()
    for i in 0..all_files.len() as i32:
        let path = all_files[i]
        if path.ends_with(".w"):
            w_files.push(with_str_clone_ref(path))
    build_cache_sorted_strings(w_files)

fn build_cache_split_lines(text: &str) -> Vec[str]:
    let lines: Vec[str] = Vec.new()
    let text_len = text.len() as i32
    var start = 0
    var i = 0
    while i <= text_len:
        var ch = 10
        if i < text_len:
            ch = text[i]
        if ch == 10:
            var line = text.slice(start as i64, i as i64)
            if line.len() > 0 and line[line.len() as i64 - 1] == 13:
                line = line.slice(0, line.len() - 1)
            if line.len() > 0:
                lines.push(line)
            start = i + 1
        i = i + 1
    lines

fn build_cache_str_compare(a: &str, b: &str) -> i32:
    let min_len = if a.len() < b.len(): a.len() else: b.len()
    var i = 0
    while i < min_len as i32:
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

fn build_cache_sorted_strings(items: &Vec[str]) -> Vec[str]:
    var sorted: Vec[str] = Vec.new()
    for i in 0..items.len() as i32:
        let item = items[i]
        var inserted = false
        var out: Vec[str] = Vec.new()
        for j in 0..sorted.len() as i32:
            let existing = sorted[j]
            if not inserted and build_cache_str_compare(item, existing) < 0:
                out.push(with_str_clone_ref(item))
                inserted = true
            out.push(with_str_clone_ref(existing))
        if not inserted:
            out.push(with_str_clone_ref(item))
        sorted = out
    sorted

fn build_cache_sorted_unique_strings(items: &Vec[str]) -> Vec[str]:
    var sorted: Vec[str] = Vec.new()
    for i in 0..items.len() as i32:
        sorted = tracked_input_insert_unique(move sorted, items[i])
    sorted

fn build_cache_last_colon(text: &str) -> i32:
    var last = -1
    for i in 0..text.len() as i32:
        if text[i] == 58:
            last = i
    last

fn build_cache_dep_path(root: &str, stored_path: &str) -> str:
    if stored_path.len() > 0 and stored_path[0] == 47:
        return with_str_clone_ref(stored_path)
    root ++ "/" ++ stored_path

fn build_cache_effect_env_state_line(effect_line: &str) -> str:
    if not effect_line.starts_with("env\t"):
        return ""
    var tab_count = 0
    var second_tab = -1
    var third_tab = -1
    for i in 0..effect_line.len() as i32:
        if effect_line[i] == 9:
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
        out = out ++ sorted[i] ++ "\n"
    out

pub fn build_cache_hash_directory_w_files(root: &str, dir: &str) -> str:
    let files = build_cache_list_w_files(root, dir)
    var combined = ""
    for i in 0..files.len() as i32:
        let path = files[i]
        combined = combined ++ path ++ ":" ++ build_cache_fingerprint_file(path) ++ "\n"
    build_cache_sha256_text(combined)

// #686: the evaluator resolves std modules from the embedded stdlib; their
// closure paths carry the embedded prefix. Hash the disk mirror (what the
// current global hash also does for std.build); a missing file hashes as a
// stable marker so path-set changes still shift the signature.
fn build_cache_action_source_disk_path(root: &str, path: &str) -> str:
    if path.starts_with("<embedded-std>/"):
        return root ++ "/lib/" ++ path.slice("<embedded-std>/".len(), path.len())
    if path.starts_with("/"):
        return with_str_clone_ref(path)
    root ++ "/" ++ path

fn build_cache_hash_action_sources(root: &str, paths: &Vec[str]) -> str:
    let unsorted: Vec[str] = Vec.new()
    for i in 0..paths.len() as i32:
        unsorted.push(with_str_clone_ref(paths[i]))
    let sorted = build_graph_sorted_strings(unsorted)
    var combined = ""
    for i in 0..sorted.len() as i32:
        let p = sorted[i]
        let disk = build_cache_action_source_disk_path(root, p)
        if build_graph_rt_file_exists(disk) != 0:
            combined = combined ++ p ++ ":" ++ build_cache_fingerprint_file(disk) ++ "\n"
        else:
            combined = combined ++ p ++ ":missing\n"
    build_cache_sha256_text(combined)

fn build_cache_hash_build_graph_sources(root: &str) -> str:
    var combined = "build.w:" ++ build_cache_fingerprint_file(root ++ "/build.w") ++ "\n"
    combined = combined ++ "build:" ++ build_cache_hash_directory_w_files(root, "build") ++ "\n"
    combined = combined ++ "std.build:" ++ build_cache_fingerprint_file(root ++ "/lib/std/build.w") ++ "\n"
    build_cache_sha256_text(combined)

// Plain content hash (no mode/exec framing) so external evidence checkers
// (build/retention.w's sha256-tool flow) can reproduce manifest entries.
pub fn build_cache_sha256_file_content(path: &str) -> str:
    build_cache_sha256_framed("", build_graph_rt_read_file(path))

fn build_cache_test_success_manifest(root: &str, target: &BuildGraphTarget, test_files: &Vec[str], test_compiler: &str) -> str:
    // v2: the test compiler and every test file are keyed by CONTENT hash.
    // v1 recorded the compiler by PATH only, so :test-green evidence
    // survived compiler rebuilds — the reference toolchains all key test
    // verdicts on compiler identity first (Go: test-binary action ID;
    // Rust compiletest: Stamp::from_path(rustc); Zig: cache.hash seeded
    // with compiler version/backend).
    var text = "v2\n"
    text = text ++ "target:" ++ target.name ++ "\n"
    text = text ++ f"kind:{target.kind}\n"
    text = text ++ "entry:" ++ target.entry ++ "\n"
    text = text ++ "output:" ++ target.output ++ "\n"
    text = text ++ f"opt:{target.optimize_mode}\n"
    text = text ++ f"target-kind:{target.target_kind}\n"
    for i in 0..target.args.len() as i32:
        text = text ++ "arg:" ++ target.args[i] ++ "\n"
    for i in 0..target.defines.len() as i32:
        text = text ++ "define:" ++ target.defines[i] ++ "\n"
    for i in 0..target.include_paths.len() as i32:
        text = text ++ "include:" ++ target.include_paths[i] ++ "\n"
    for i in 0..target.system_libs.len() as i32:
        text = text ++ "lib:" ++ target.system_libs[i] ++ "\n"
    let compiler_rel = build_cache_project_relative(root, test_compiler)
    if compiler_rel.len() > 0:
        text = text ++ "compiler:" ++ compiler_rel ++ "\n"
        text = text ++ "compiler-sha256:" ++ build_cache_sha256_file_content(test_compiler) ++ "\n"
    else:
        text = text ++ "compiler:\n"
        text = text ++ "compiler-sha256:\n"
    let rel_files: Vec[str] = Vec.new()
    for i in 0..test_files.len() as i32:
        rel_files.push(build_cache_project_relative(root, test_files[i]))
    let sorted = build_cache_sorted_strings(rel_files)
    for i in 0..sorted.len() as i32:
        let path = sorted[i]
        text = text ++ "file:" ++ path ++ ":" ++ build_cache_sha256_file_content(build_cache_dep_path(root, path)) ++ "\n"
    text

pub fn build_cache_record_test_success(root: &str, target: &BuildGraphTarget, test_files: &Vec[str], test_compiler: &str) -> Unit:
    build_cache_forget_fingerprints()
    let state_dir = build_cache_state_dir(root)
    let _mkdir = build_graph_rt_mkdir_p(state_dir)
    let marker_path = build_cache_test_success_path(root, target.name)
    let marker = build_cache_test_success_manifest(root, target, test_files, test_compiler)
    let _write = build_graph_rt_write_file(marker_path, marker)

// ── Per-file test verdict cache ─────────────────────────────────────
//
// A test file's PASS verdict is cached under a key that changes when any
// of these change: the test compiler binary (content fingerprint — the
// unanimous reference-toolchain design), the test file itself, the
// target's configuration (args/defines/includes/libs/opt), or the
// harness-relevant environment. Only PASSES are cached (Go semantics);
// failures always re-run. The verdict store is rewritten after every
// target run with exactly the currently-passing key set, so stale keys
// compact away and a red target still banks the green files it proved —
// the next run re-executes only failures and changed files.

pub fn build_cache_test_verdicts_path(root: &str, target_name: &str) -> str:
    build_cache_state_dir(root) ++ "/" ++ target_name ++ ".test-verdicts"

fn build_cache_test_target_sig_text(target: &BuildGraphTarget) -> str:
    var sig = f"opt:{target.optimize_mode}\n"
    for i in 0..target.args.len() as i32:
        sig = sig ++ "arg:" ++ target.args[i] ++ "\n"
    for i in 0..target.defines.len() as i32:
        sig = sig ++ "define:" ++ target.defines[i] ++ "\n"
    for i in 0..target.include_paths.len() as i32:
        sig = sig ++ "include:" ++ target.include_paths[i] ++ "\n"
    for i in 0..target.system_libs.len() as i32:
        sig = sig ++ "lib:" ++ target.system_libs[i] ++ "\n"
    sig = sig ++ "env:WITH_MEMORY_LIMIT_BYTES=" ++ build_graph_rt_getenv("WITH_MEMORY_LIMIT_BYTES") ++ "\n"
    sig

pub fn build_cache_test_compiler_fingerprint(compiler_path: &str) -> str:
    // The stamped binary differs across commits only in its version slot
    // (D13: the stamp is provenance, not semantics). Key verdicts on the
    // unstamped sibling when it exists so banked passes survive
    // commit-identity-only changes; fall back for compilers with no sibling.
    let unstamped = compiler_path ++ ".unstamped"
    if build_graph_rt_file_exists(unstamped) != 0:
        return build_cache_fingerprint_file(unstamped)
    build_cache_fingerprint_file(compiler_path)

pub fn build_cache_test_verdict_key(root: &str, target: &BuildGraphTarget, compiler_fp: &str, test_path: &str) -> str:
    // The relative path is part of the key: content-identical files are
    // *almost* behavior-identical, but tests resolve siblings (c_import
    // headers) relative to their own location.
    build_cache_sha256_text("test-verdict\n" ++ build_cache_test_target_sig_text(target) ++ "compiler:" ++ compiler_fp ++ "\npath:" ++ build_cache_project_relative(root, test_path) ++ "\nfile:" ++ build_cache_fingerprint_file(test_path) ++ "\n")

pub fn build_cache_load_test_verdicts(root: &str, target_name: &str) -> HashMap[str, i32]:
    let out: HashMap[str, i32] = HashMap.new()
    let path = build_cache_test_verdicts_path(root, target_name)
    if build_graph_rt_file_exists(path) == 0:
        return out
    let text = build_graph_rt_read_file(path)
    var line_start = 0
    var i = 0
    while i <= text.len() as i32:
        if i == text.len() as i32 or text[i] == 10:
            let line = text.slice(line_start as i64, i as i64)
            if line.starts_with("pass:"):
                let rest = line.slice(5, line.len())
                var colon = -1
                for ci in 0..rest.len() as i32:
                    if rest[ci] == 58:
                        colon = ci
                        break
                let key = if colon >= 0: rest.slice(0, colon as i64) else: rest
                if key.len() > 0:
                    out.insert(key, 1)
            line_start = i + 1
        i = i + 1
    out

pub fn build_cache_write_test_verdicts(root: &str, target_name: &str, keys: &Vec[str], rel_paths: &Vec[str]) -> Unit:
    let state_dir = build_cache_state_dir(root)
    let _mkdir = build_graph_rt_mkdir_p(state_dir)
    var text = "v1\n"
    for i in 0..keys.len() as i32:
        text = text ++ "pass:" ++ keys[i] ++ ":" ++ rel_paths[i] ++ "\n"
    let _write = build_graph_rt_write_file(build_cache_test_verdicts_path(root, target_name), text)

pub fn build_cache_project_relative_path(root: &str, path: &str) -> str:
    build_cache_project_relative(root, path)

fn build_cache_compute_signature(target: &BuildGraphTarget, root: &str) -> str:
    var sig = f"{target.kind}:{target.name}:{target.entry}:{target.output}"
    sig = sig ++ f":{target.optimize_mode}:{target.target_kind}"
    for i in 0..target.args.len() as i32:
        sig = sig ++ ":" ++ target.args[i]
    for i in 0..target.defines.len() as i32:
        sig = sig ++ ":D:" ++ target.defines[i]
    for i in 0..target.include_paths.len() as i32:
        sig = sig ++ ":I:" ++ target.include_paths[i]
    for i in 0..target.system_libs.len() as i32:
        sig = sig ++ ":L:" ++ target.system_libs[i]
    if build_cache_target_uses_current_compiler(target):
        sig = sig ++ ":WITH:" ++ build_cache_current_compiler_fingerprint()
    if target.kind == 23:
        // #686: hash only the modules the action's code can reach (defining
        // file + use closure, computed at materialize). A build.w-only edit
        // no longer invalidates actions whose code lives in build/ modules.
        // Empty closure (mapping unavailable) falls back to hashing all
        // build-graph sources — the always-safe superset.
        if target.action_source_paths.len() > 0:
            sig = sig ++ ":ACTION_CODE:" ++ build_cache_hash_action_sources(root, &target.action_source_paths)
        else:
            sig = sig ++ ":BUILD_GRAPH:" ++ build_cache_hash_build_graph_sources(root)
    if build_cache_is_stage_target(target):
        let src_hash = build_cache_hash_directory_w_files(root, "src")
        sig = sig ++ ":SRC:" ++ src_hash
        let compiler_path = build_cache_target_compiler_path(root, target)
        if compiler_path.len() > 0:
            let compiler_hash = build_cache_fingerprint_file(compiler_path)
            sig = sig ++ ":COMPILER:" ++ compiler_hash
    build_cache_sha256_text(sig)

fn build_cache_collect_input_paths(root: &str, target: &BuildGraphTarget) -> Vec[str]:
    var paths: Vec[str] = Vec.new()
    if target.entry.len() > 0:
        paths.push(root ++ "/" ++ target.entry)
    for i in 0..target.inputs.len() as i32:
        let input = target.inputs[i]
        if input.len() > 0:
            paths.push(root ++ "/" ++ input)
    paths

fn build_cache_collect_output_paths(root: &str, target: &BuildGraphTarget) -> Vec[str]:
    var paths: Vec[str] = Vec.new()
    if target.output.len() > 0:
        paths.push(root ++ "/" ++ target.output)
    for i in 0..target.extra_outputs.len() as i32:
        let extra = target.extra_outputs[i]
        if extra.len() > 0:
            paths.push(root ++ "/" ++ extra)
    paths

pub fn build_cache_freshness_reason(root: &str, target: &BuildGraphTarget, dep_rebuilt: bool) -> str:
    if not build_cache_is_cacheable(target.kind):
        return "not cacheable"
    if target.name == "prune" or target.name == "prune-apply":
        return "stale: target is always run"
    if target.name == "last-green" or target.name == "test-green" or target.name == "require-last-green" or target.name == "check-committed-state" or target.name == "print-version":
        return "stale: target is always run"
    // Publishing is not a function of declared inputs (env-driven, and the
    // release's add-only rule is what refuses a duplicate): never a cache hit.
    // A name, like the lanes above: a Target flag would be a std.build API
    // the pinned seed evaluating build.w does not have (the bootstrap rule).
    if target.name == "publish-release-asset":
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
        let byte = state_text[i]
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
        let path = input_paths[idx]
        let current_hash = build_cache_fingerprint_file(path)
        let stored = input_hashes[idx]
        let expected_entry = path ++ ":" ++ current_hash
        if stored != expected_entry:
            return "stale: input changed: " ++ build_cache_project_relative(root, path)
    for idx in 0..dep_hashes.len() as i32:
        let stored = dep_hashes[idx]
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
        let stored = env_hashes[idx]
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
        let path = output_paths[idx]
        if build_graph_rt_file_exists(path) == 0:
            return "stale: output missing: " ++ build_cache_project_relative(root, path)
        let current_hash = build_cache_fingerprint_file(path)
        let stored = output_hashes[idx]
        let expected_entry = path ++ ":" ++ current_hash
        if stored != expected_entry:
            return "stale: output changed: " ++ build_cache_project_relative(root, path)
    "fresh"

pub fn build_cache_check_fresh(root: &str, target: &BuildGraphTarget, dep_rebuilt: bool) -> bool:
    build_cache_freshness_reason(root, target, dep_rebuilt) == "fresh"

pub fn build_cache_record(root: &str, target: &BuildGraphTarget, discovered_deps: &Vec[str], effects: &Vec[str]) -> Unit:
    build_cache_forget_fingerprints()
    let state_dir = build_cache_state_dir(root)
    let _ = build_graph_rt_mkdir_p(state_dir)
    let state_path = build_cache_state_path(root, target.name)
    let sig = build_cache_compute_signature(target, root)
    var content = "v2\nsig:" ++ sig ++ "\n"
    if build_cache_target_uses_current_compiler(target):
        content = content ++ "compiler:" ++ build_cache_current_compiler_fingerprint() ++ "\n"
    let input_paths = build_cache_collect_input_paths(root, target)
    for idx in 0..input_paths.len() as i32:
        let path = input_paths[idx]
        let hash = build_cache_fingerprint_file(path)
        content = content ++ "in:" ++ path ++ ":" ++ hash ++ "\n"
    let dep_paths = build_cache_sorted_unique_strings(discovered_deps)
    for idx in 0..dep_paths.len() as i32:
        let path = dep_paths[idx]
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
            let env_line = build_cache_effect_env_state_line(sorted_effects[idx])
            if env_line.len() > 0:
                content = content ++ env_line ++ "\n"
    else:
        let _remove_effects = build_graph_rt_remove_file(build_cache_effects_path(root, target.name))
    let output_paths = build_cache_collect_output_paths(root, target)
    for idx in 0..output_paths.len() as i32:
        let path = output_paths[idx]
        let hash = build_cache_fingerprint_file(path)
        content = content ++ "out:" ++ path ++ ":" ++ hash ++ "\n"
    let _ = build_graph_rt_write_file(state_path, content)

pub fn build_cache_record_build_effects(root: &str, effects: &Vec[str]) -> Unit:
    let state_dir = build_cache_state_dir(root)
    let _ = build_graph_rt_mkdir_p(state_dir)
    let effects_text = build_cache_effects_text(effects)
    let path = build_cache_build_effects_path(root)
    if effects_text.len() > 0:
        let _write = build_graph_rt_write_file(path, effects_text)
    else:
        let _remove = build_graph_rt_remove_file(path)

pub fn build_cache_print_effects(root: &str, graph: &BuildGraph, target_filter: &str) -> i32:
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
        let target = &graph.targets[ti]
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

// ── D19/#702: evaluated-graph cache ────────────────────────────────
//
// Every `with build` invocation comptime-evaluates build.w (~5s) before it
// knows what was asked — including every worker spawn inside a battery. The
// evaluated graph is pure data (targets, strings, generated sources), so it
// serializes; the cache key is the build-source hash plus the runner's own
// fingerprint plus the options that shape the graph. Action workers must
// NOT load from this cache: evaluating an action needs the live Sema the
// real load produces. Length-prefixed strings survive arbitrary bytes.

pub fn build_cache_graph_path(root: &str) -> str:
    build_cache_state_dir(root) ++ "/build-graph.cache"

pub fn build_cache_graph_key(root: &str, target_kind: i32, strict_effects: i32) -> str:
    build_cache_hash_build_graph_sources(root) ++ ":" ++ build_cache_current_compiler_fingerprint() ++ ":" ++ build_cache_fingerprint_file(root ++ "/with.toml") ++ f":{target_kind}:{strict_effects}"

fn bcg_put_str(out: &str, s: &str) -> str:
    out ++ f"s{s.len()}\n" ++ s ++ "\n"

fn bcg_put_list(out: &str, items: &Vec[str]) -> str:
    var acc = out ++ f"l{items.len()}\n"
    for i in 0..items.len() as i32:
        acc = bcg_put_str(acc, items[i])
    acc

pub fn build_cache_graph_write(root: &str, key: &str, graph: &BuildGraph) -> Unit:
    if not graph.ok:
        return
    var out = "WGRAPH1\n"
    out = bcg_put_str(out, key)
    out = bcg_put_str(out, graph.package_name)
    out = bcg_put_str(out, graph.package_version)
    out = bcg_put_str(out, graph.default_target)
    out = bcg_put_str(out, graph.raw_text)
    out = out ++ f"t{graph.targets.len()}\n"
    for i in 0..graph.targets.len() as i32:
        let t = &graph.targets[i]
        out = out ++ f"i {t.kind} {t.target_kind} {t.optimize_mode} {t.action_fn} {t.timeout_ms} {t.network} {t.parallel}\n"
        out = bcg_put_str(out, t.name)
        out = bcg_put_str(out, t.entry)
        out = bcg_put_str(out, t.output)
        out = bcg_put_str(out, t.cwd)
        out = bcg_put_list(out, &t.system_libs)
        out = bcg_put_list(out, &t.include_paths)
        out = bcg_put_list(out, &t.defines)
        out = bcg_put_list(out, &t.inputs)
        out = bcg_put_list(out, &t.extra_outputs)
        out = bcg_put_list(out, &t.write_scopes)
        out = bcg_put_list(out, &t.deps)
        out = bcg_put_list(out, &t.args)
        out = bcg_put_list(out, &t.env)
        out = bcg_put_list(out, &t.action_source_paths)
    out = out ++ f"g{graph.generated_sources.len()}\n"
    for i in 0..graph.generated_sources.len() as i32:
        let g = graph.generated_sources[i]
        out = bcg_put_str(out, g.path)
        out = bcg_put_str(out, g.contents)
    let _mk = build_graph_rt_mkdir_p(build_cache_state_dir(root))
    let _w = build_graph_rt_write_file(build_cache_graph_path(root), out)

type BcgReader {
    text: str,
    pos: i64,
    ok: bool,
}

fn bcg_parse_i64(s: &str) -> i64:
    var out: i64 = 0
    var neg = false
    var i: i64 = 0
    if s.len() > 0 and s[0] == 45:
        neg = true
        i = 1
    while i < s.len():
        let ch = s[i]
        if ch < 48 or ch > 57:
            return if neg: -out else: out
        out = out * 10 + (ch - 48) as i64
        i = i + 1
    if neg: -out else: out

impl BcgReader:
    mut fn read_line() -> str:
        if not self.ok:
            return ""
        var end = self.pos
        while end < self.text.len() and self.text[end] != 10:
            end = end + 1
        if end >= self.text.len():
            self.ok = false
            return ""
        let line = self.text.slice(self.pos, end)
        self.pos = end + 1
        line

    mut fn read_str() -> str:
        let header = self.read_line()
        if not self.ok or header.len() == 0 or header[0] != 115:
            self.ok = false
            return ""
        let n = bcg_parse_i64(header.slice(1, header.len()))
        if n < 0 or self.pos + n + 1 > self.text.len():
            self.ok = false
            return ""
        let s = self.text.slice(self.pos, self.pos + n)
        self.pos = self.pos + n + 1
        s

    mut fn read_list() -> Vec[str]:
        var out: Vec[str] = Vec.new()
        let header = self.read_line()
        if not self.ok or header.len() == 0 or header[0] != 108:
            self.ok = false
            return out
        let n = bcg_parse_i64(header.slice(1, header.len()))
        for i in 0..n as i32:
            out.push(self.read_str())
        out

pub fn build_cache_graph_try_read(root: &str, key: &str) -> BuildGraph:
    var graph = empty_build_graph()
    let text = build_graph_rt_read_file(build_cache_graph_path(root))
    if text.len() == 0:
        return graph
    var r = BcgReader { text: text, pos: 0, ok: true }
    if r.read_line() != "WGRAPH1":
        return graph
    if r.read_str() != key or not r.ok:
        return graph
    graph.package_name = r.read_str()
    graph.package_version = r.read_str()
    graph.default_target = r.read_str()
    graph.raw_text = r.read_str()
    let theader = r.read_line()
    if not r.ok or theader.len() == 0 or theader[0] != 116:
        return graph
    let tcount = bcg_parse_i64(theader.slice(1, theader.len()))
    for ti in 0..tcount as i32:
        let iline = r.read_line()
        if not r.ok or iline.len() < 2 or iline[0] != 105:
            return empty_build_graph()
        let nums = iline.slice(2, iline.len()).split(" ")
        if nums.len() != 7:
            return empty_build_graph()
        var t = empty_build_graph_target()
        t.kind = bcg_parse_i64(nums.get(0)) as i32
        t.target_kind = bcg_parse_i64(nums.get(1)) as i32
        t.optimize_mode = bcg_parse_i64(nums.get(2)) as i32
        t.action_fn = bcg_parse_i64(nums.get(3)) as i32
        t.timeout_ms = bcg_parse_i64(nums.get(4)) as i32
        t.network = bcg_parse_i64(nums.get(5)) as i32
        t.parallel = bcg_parse_i64(nums.get(6)) as i32
        t.name = r.read_str()
        t.entry = r.read_str()
        t.output = r.read_str()
        t.cwd = r.read_str()
        t.system_libs = r.read_list()
        t.include_paths = r.read_list()
        t.defines = r.read_list()
        t.inputs = r.read_list()
        t.extra_outputs = r.read_list()
        t.write_scopes = r.read_list()
        t.deps = r.read_list()
        t.args = r.read_list()
        t.env = r.read_list()
        t.action_source_paths = r.read_list()
        if not r.ok:
            return empty_build_graph()
        graph.targets.push(move t)
    let gheader = r.read_line()
    if not r.ok or gheader.len() == 0 or gheader[0] != 103:
        return empty_build_graph()
    let gcount = bcg_parse_i64(gheader.slice(1, gheader.len()))
    for gi in 0..gcount as i32:
        let path = r.read_str()
        let contents = r.read_str()
        if not r.ok:
            return empty_build_graph()
        graph.generated_sources.push(BuildGraphGeneratedSource { path: path, contents: contents })
    if not r.ok:
        return empty_build_graph()
    graph.ok = true
    graph
