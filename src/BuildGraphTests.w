// BuildGraphTests -- native test graph target execution.

use Resolve
use BuildGraphModel
use BuildGraphRuntime
use BuildGraphSupport

type BuildGraphExternalTestJob {
    test_path: str,
    stdout_path: str,
    stderr_path: str,
    pid: i32,
}

pub fn build_graph_test_target_files(root: str, entry: str) -> Vec[str]:
    let files: Vec[str] = Vec.new()
    if not build_graph_path_has_glob(entry):
        files.push(resolve_join(root, entry))
        return files

    let entry_dir = build_graph_dirname(entry)
    let pattern = build_graph_path_basename(entry)
    let search_dir = if entry_dir == ".": root else: build_graph_resolve_project_path(root, entry_dir)
    let candidates = collect_test_files(search_dir)
    for ci in 0..candidates.len() as i32:
        let candidate = candidates.get(ci as i64)
        let candidate_dir = build_graph_dirname(candidate)
        if candidate_dir != search_dir:
            continue
        let base = build_graph_path_basename(candidate)
        if build_graph_single_star_pattern_matches(pattern, base):
            files.push(candidate)
    files

fn build_graph_test_compiler_arg(arg: str) -> str:
    let prefix = "compiler="
    if arg.starts_with(prefix):
        return arg.slice(prefix.len(), arg.len())
    ""

pub fn build_graph_test_compiler(root: str, target: &BuildGraphTarget) -> str:
    for ai in 0..target.args.len() as i32:
        let value = build_graph_test_compiler_arg(target.args.get(ai as i64))
        if value.len() > 0:
            return build_graph_resolve_project_path(root, value)
    ""

fn build_graph_append_test_args(argv: str, target: &BuildGraphTarget) -> str:
    var out = argv
    for ai in 0..target.args.len() as i32:
        let arg = target.args.get(ai as i64)
        if build_graph_test_compiler_arg(arg).len() == 0:
            out = build_graph_argv_append(out, arg)
    out

fn build_graph_test_parse_jobs(value: str) -> i32:
    var out = 0
    for i in 0..value.len() as i32:
        let ch = value.byte_at(i as i64)
        if ch < 48 or ch > 57:
            break
        out = out * 10 + (ch - 48)
    out

fn build_graph_test_jobs -> i32:
    let raw = build_graph_rt_getenv("WITH_BUILD_TEST_JOBS")
    let parsed = build_graph_test_parse_jobs(raw)
    if parsed <= 0:
        return 4
    if parsed > 32:
        return 32
    parsed

fn build_graph_external_test_argv(root: str, target: &BuildGraphTarget, compiler_path: str, test_path: str) -> str:
    var argv = ""
    argv = build_graph_argv_append(argv, compiler_path)
    argv = build_graph_argv_append(argv, "test")
    argv = build_graph_append_test_args(argv, target)
    argv = build_graph_argv_append(argv, "--quiet")
    argv = build_graph_argv_append(argv, build_graph_path_for_child_process(root, test_path))
    argv

fn build_graph_external_test_job_new(test_path: str, stdout_path: str, stderr_path: str, pid: i32) -> BuildGraphExternalTestJob:
    BuildGraphExternalTestJob { test_path, stdout_path, stderr_path, pid }

pub fn build_graph_run_external_test_file(root: str, target: &BuildGraphTarget, compiler_path: str, test_path: str) -> i32:
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

fn build_graph_wait_external_test_job(target: &BuildGraphTarget, job: BuildGraphExternalTestJob) -> i32:
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

pub fn build_graph_run_external_test_files(root: str, target: &BuildGraphTarget, compiler_path: str, test_files: &Vec[str]) -> i32:
    let capture_dir = resolve_join(resolve_join(root, "out/test-graph"), target.name)
    if build_graph_rt_mkdir_p(capture_dir) != 0:
        build_graph_rt_eprint("error: could not create test output directory for target '" ++ target.name ++ "': " ++ capture_dir)
        return 1
    let jobs_limit = build_graph_test_jobs()
    var next = 0
    while next < test_files.len() as i32:
        let active: Vec[BuildGraphExternalTestJob] = Vec.new()
        while next < test_files.len() as i32 and active.len() < jobs_limit as i64:
            let test_path = test_files.get(next as i64)
            let base = build_graph_path_basename(test_path)
            let stdout_path = resolve_join(capture_dir, base ++ ".stdout")
            let stderr_path = resolve_join(capture_dir, base ++ ".stderr")
            let argv = build_graph_external_test_argv(root, target, compiler_path, test_path)
            let pid = build_graph_rt_exec_argv_capture_spawn(argv, stdout_path, stderr_path)
            if pid <= 0:
                build_graph_rt_eprint("error: build.w test target '" ++ target.name ++ "' could not spawn '" ++ test_path ++ "'")
                return 1
            active.push(build_graph_external_test_job_new(test_path, stdout_path, stderr_path, pid))
            next = next + 1
        var first_failure = 0
        for ai in 0..active.len() as i32:
            let rc = build_graph_wait_external_test_job(target, active.get(ai as i64))
            if rc != 0 and first_failure == 0:
                first_failure = rc
        if first_failure != 0:
            return first_failure
    0
