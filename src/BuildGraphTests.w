// BuildGraphTests -- native test graph target execution.

use Resolve
use BuildGraphModel
use BuildGraphRuntime
use BuildGraphSupport
use BuildGraphCache

extern fn with_str_clone_ref(s: &str) -> str

type BuildGraphExternalTestJob {
    test_path: str,
    stdout_path: str,
    stderr_path: str,
    pid: i32,
}

pub fn build_graph_test_target_files(root: &str, entry: &str) -> Vec[str]:
    let files: Vec[str] = Vec.new()
    if not build_graph_path_has_glob(entry):
        files.push(resolve_join(root, entry))
        return files

    let entry_dir = build_graph_dirname(entry)
    let pattern = build_graph_path_basename(entry)
    let search_dir = if entry_dir == ".": with_str_clone_ref(root) else: build_graph_resolve_project_path(root, entry_dir)
    let candidates = collect_test_files(search_dir)
    for ci in 0..candidates.len() as i32:
        let candidate = candidates[ci]
        let candidate_dir = build_graph_dirname(candidate)
        if candidate_dir != search_dir:
            continue
        let base = build_graph_path_basename(candidate)
        if build_graph_single_star_pattern_matches(pattern, base):
            files.push(with_str_clone_ref(candidate))
    files

fn build_graph_test_compiler_arg(arg: &str) -> str:
    let prefix = "compiler="
    if arg.starts_with(prefix):
        return arg.slice(prefix.len(), arg.len())
    ""

pub fn build_graph_test_compiler(root: &str, target: &BuildGraphTarget) -> str:
    for ai in 0..target.args.len() as i32:
        let value = build_graph_test_compiler_arg(target.args[ai])
        if value.len() > 0:
            return build_graph_resolve_project_path(root, value)
    ""

fn build_graph_append_test_args(argv: &str, target: &BuildGraphTarget) -> str:
    var out = with_str_clone_ref(argv)
    for ai in 0..target.args.len() as i32:
        let arg = target.args[ai]
        if build_graph_test_compiler_arg(arg).len() == 0:
            out = build_graph_argv_append(out, arg)
    out

fn build_graph_test_parse_jobs(value: &str) -> i32:
    var out = 0
    for i in 0..value.len() as i32:
        let ch = value[i]
        if ch < 48 or ch > 57:
            break
        out = out * 10 + (ch - 48)
    out

fn build_graph_test_jobs -> i32:
    let raw = build_graph_rt_getenv("WITH_BUILD_TEST_JOBS")
    let parsed = build_graph_test_parse_jobs(raw)
    if parsed <= 0:
        // Default to host core width; test children are small compared to
        // the driver, so cores — not a fixed 4 — is the right ceiling.
        let cores = build_graph_rt_cpu_cores()
        if cores < 1:
            return 4
        if cores > 32:
            return 32
        return cores
    if parsed > 32:
        return 32
    parsed

fn build_graph_external_test_argv(root: &str, target: &BuildGraphTarget, compiler_path: &str, test_path: &str) -> str:
    var argv = ""
    argv = build_graph_argv_append(argv, compiler_path)
    argv = build_graph_argv_append(argv, "test")
    argv = build_graph_append_test_args(argv, target)
    argv = build_graph_argv_append(argv, "--quiet")
    argv = build_graph_argv_append(argv, build_graph_path_for_child_process(root, test_path))
    argv

fn build_graph_external_test_job_new(test_path: &str, stdout_path: &str, stderr_path: &str, pid: i32) -> BuildGraphExternalTestJob:
    BuildGraphExternalTestJob { test_path: with_str_clone_ref(test_path), stdout_path: with_str_clone_ref(stdout_path), stderr_path: with_str_clone_ref(stderr_path), pid }

pub fn build_graph_run_external_test_file(root: &str, target: &BuildGraphTarget, compiler_path: &str, test_path: &str) -> i32:
    let capture_dir = resolve_join(resolve_join(root, "out/test-graph"), target.name)
    if build_graph_rt_mkdir_p(capture_dir) != 0:
        build_graph_rt_eprint("error: could not create test output directory for target '" ++ target.name ++ "': " ++ capture_dir)
        return 1
    let base = build_graph_path_basename(test_path)
    let stdout_path = resolve_join(capture_dir, base ++ ".stdout")
    let stderr_path = resolve_join(capture_dir, base ++ ".stderr")
    let argv = build_graph_external_test_argv(root, target, compiler_path, test_path)
    let rc = build_graph_rt_exec_argv_capture(argv, stdout_path, stderr_path, 300000)
    if rc == 124:
        build_graph_rt_eprint("error: build.w test target '" ++ target.name ++ "' timed out in '" ++ test_path ++ "'; stdout=" ++ stdout_path ++ " stderr=" ++ stderr_path)
        return 124
    if rc != 0:
        build_graph_rt_eprint("error: build.w test target '" ++ target.name ++ "' failed in '" ++ test_path ++ f"' with exit code {rc}; stdout=" ++ stdout_path ++ " stderr=" ++ stderr_path)
        return rc
    let _remove_stdout = build_graph_rt_remove_file(stdout_path)
    let _remove_stderr = build_graph_rt_remove_file(stderr_path)
    0

fn build_graph_wait_external_test_job(target: &BuildGraphTarget, job: &BuildGraphExternalTestJob) -> i32:
    let rc = build_graph_rt_exec_wait(job.pid, 300000)
    if rc == 124:
        build_graph_rt_eprint("error: build.w test target '" ++ target.name ++ "' timed out in '" ++ job.test_path ++ "'; stdout=" ++ job.stdout_path ++ " stderr=" ++ job.stderr_path)
        return 124
    if rc != 0:
        build_graph_rt_eprint("error: build.w test target '" ++ target.name ++ "' failed in '" ++ job.test_path ++ f"' with exit code {rc}; stdout=" ++ job.stdout_path ++ " stderr=" ++ job.stderr_path)
        return rc
    let _remove_stdout = build_graph_rt_remove_file(job.stdout_path)
    let _remove_stderr = build_graph_rt_remove_file(job.stderr_path)
    0

pub fn build_graph_run_external_test_files(root: &str, target: &BuildGraphTarget, compiler_path: &str, test_files: &Vec[str]) -> i32:
    let capture_dir = resolve_join(resolve_join(root, "out/test-graph"), target.name)
    if build_graph_rt_mkdir_p(capture_dir) != 0:
        build_graph_rt_eprint("error: could not create test output directory for target '" ++ target.name ++ "': " ++ capture_dir)
        return 1

    // Per-file verdict cache: skip files whose PASS verdict was recorded
    // under the same (compiler fingerprint, file fingerprint, target
    // config) key. Only passes are cached; failures always re-run. A red
    // run still banks every green verdict it proved, so the next run
    // re-executes only failures and changed files — never the whole
    // alphabet again.
    let compiler_fp = build_cache_test_compiler_fingerprint(compiler_path)
    let prior = build_cache_load_test_verdicts(root, target.name)
    var pass_keys: Vec[str] = Vec.new()
    var pass_paths: Vec[str] = Vec.new()
    var run_files: Vec[str] = Vec.new()
    var run_keys: Vec[str] = Vec.new()
    var cached_count = 0
    for i in 0..test_files.len() as i32:
        let test_path = test_files[i]
        let key = build_cache_test_verdict_key(root, target, compiler_fp, test_path)
        if prior.contains(key):
            cached_count = cached_count + 1
            pass_keys.push(key)
            pass_paths.push(build_cache_project_relative_path(root, test_path))
        else:
            run_files.push(with_str_clone_ref(test_path))
            run_keys.push(key)

    // Run every non-cached file; report every failure; never abort the
    // sweep on the first one (fail-fast over alphabetically ordered files
    // is how ten gate chains each surfaced exactly one bug).
    let jobs_limit = build_graph_test_jobs()
    var failed_paths: Vec[str] = Vec.new()
    var first_failure = 0
    var next = 0
    var oldest = 0
    let active: Vec[BuildGraphExternalTestJob] = Vec.new()
    let active_keys: Vec[str] = Vec.new()
    // Sliding window: keep jobs_limit children in flight, retiring the oldest
    // to open each slot (no batch barrier — one slow file no longer idles the
    // rest of the window).
    while oldest < run_files.len() as i32:
        if next < run_files.len() as i32 and next - oldest < jobs_limit:
            let test_path = run_files[next]
            let base = build_graph_path_basename(test_path)
            let stdout_path = resolve_join(capture_dir, base ++ ".stdout")
            let stderr_path = resolve_join(capture_dir, base ++ ".stderr")
            let argv = build_graph_external_test_argv(root, target, compiler_path, test_path)
            let pid = build_graph_rt_exec_argv_capture_spawn(argv, stdout_path, stderr_path)
            if pid <= 0:
                build_graph_rt_eprint("error: build.w test target '" ++ target.name ++ "' could not spawn '" ++ test_path ++ "'")
                return 1
            active.push(build_graph_external_test_job_new(test_path, stdout_path, stderr_path, pid))
            active_keys.push(with_str_clone_ref(run_keys[next]))
            next = next + 1
            continue
        let job_path = active[oldest].test_path
        let rc = build_graph_wait_external_test_job(target, active[oldest])
        if rc == 0:
            pass_keys.push(with_str_clone_ref(active_keys[oldest]))
            pass_paths.push(build_cache_project_relative_path(root, job_path))
        else:
            failed_paths.push(with_str_clone_ref(job_path))
            if first_failure == 0:
                first_failure = rc
        oldest = oldest + 1

    // Persist the passing set even when the target is red (compaction:
    // the file is rewritten with exactly the keys proven this run plus
    // the still-valid cached ones).
    build_cache_write_test_verdicts(root, target.name, &pass_keys, &pass_paths)

    if failed_paths.len() as i32 > 0:
        build_graph_rt_eprint(f"error: build.w test target '{target.name}': {failed_paths.len() as i32} of {test_files.len() as i32} files failed ({cached_count} cached, {run_files.len() as i32} ran):")
        for fi in 0..failed_paths.len() as i32:
            build_graph_rt_eprint("error:   failed: " ++ failed_paths[fi])
        return first_failure
    build_graph_rt_eprint(f"test target '{target.name}': {test_files.len() as i32} files ok ({cached_count} cached, {run_files.len() as i32} ran)")
    0
