// std.process — Process utility functions
//
// Provides process-level operations via the runtime interface.
// No c_import — uses with_* runtime functions.

use std.collections

extern fn with_str_clone_ref(s: &str) -> str
extern fn rt_exit(code: i32) -> Never
extern fn with_getpid() -> i32
extern fn with_exec_argv(args: &str) -> i32
extern fn with_arg_count() -> i32
extern fn with_arg_at(idx: i32) -> str
extern fn with_getenv_str(name: &str) -> str
extern fn with_setenv_str(name: &str, value: &str) -> i32
extern fn with_vec_new_out(v: *mut u8, elem_size: i64) -> Unit
// The vec RETAINS the pushed header — ownership transfers, unlike every
// read-only str extern (§16.3d declared effect; the bit-copy default would
// leave two owners).
@[effect(val: escape_value)]
extern fn with_vec_push_str(v: *mut u8, val: str) -> Unit
extern fn with_str_len(s: &str) -> i64
extern fn with_exec_argv_capture_cwd(args: &str, stdout_path: &str, stderr_path: &str, timeout_ms: i32, cwd: &str) -> i32
extern fn with_exec_argv_capture_spawn(args: &str, stdout_path: &str, stderr_path: &str) -> i32
extern fn with_exec_try_wait(pid: i32) -> i32
extern fn with_exec_wait(pid: i32, timeout_ms: i32) -> i32
extern fn with_exec_child_maxrss() -> i64
extern fn with_clock_nanos() -> i64
extern fn with_nanosleep(ns: i64) -> i32

/// Exit the process with the given status code.
pub fn exit_code(code: i32) -> Never:
    rt_exit(code)

/// Get the current process ID.
pub fn pid -> i32:
    with_getpid()

/// Get command-line arguments as a List of strings.
pub fn args -> List[str]:
    let n = with_arg_count()
    let out: List[str] = List{ ptr: 0, len: 0, cap: 0, elem_size: 0 }
    with_vec_new_out((&raw mut out) as *mut u8, 16)
    var i = 0
    while i < n:
        with_vec_push_str((&raw mut out) as *mut u8, with_arg_at(i))
        i = i + 1
    out

/// Get an environment variable. Returns "" if not set.
pub fn env(name: &str) -> str:
    let v = with_getenv_str(name)
    if with_str_len(v) == 0: "" else: v

/// Set an environment variable. Returns 0 on success.
pub fn set_env(name: &str, value: &str) -> i32:
    with_setenv_str(name, value)

fn argv_blob(items: &List[str]) -> str:
    var out = ""
    for i in 0..items.len() as i32:
        out = out ++ items[i] ++ "\0"
    out

/// Execute an argument vector. The first item is the program name.
pub fn run(argv: &List[str]) -> i32:
    with_exec_argv(argv_blob(argv))

/// How a child run with its output sent to files finished.
pub type Finished {
    /// The exit code: 128 + the signal number when a signal ended it,
    /// 127 when the program could not be started, -1 when it could not be
    /// spawned or waited for.
    pub code: i32,
    /// The timeout ended it; the child and its process group were killed.
    pub timed_out: bool,
    /// The child's peak resident set size in bytes, 0 where the platform
    /// reports none.
    pub peak_rss: i64,
}

/// Run an argument vector with its stdout and stderr written to the named
/// files, and wait for it. `timeout_ms` of 0 waits for as long as it runs.
///
/// The wait ends within 0.1% of the child's run time (and never later than
/// 1 ms), so wall-clock timing around the call measures the child: a
/// stopwatch, not a scheduler tick.
pub fn run_to_files(argv: &List[str], stdout_path: &str, stderr_path: &str, timeout_ms: i32) -> Finished:
    let pid = with_exec_argv_capture_spawn(argv_blob(argv), stdout_path, stderr_path)
    if pid <= 0: return Finished { code: -1, timed_out: false, peak_rss: 0 }
    if timeout_ms <= 0: return finished(with_exec_wait(pid, 0), false)
    let start = with_clock_nanos()
    let deadline = timeout_ms as i64 * 1000000
    while true:
        let code = with_exec_try_wait(pid)
        if code != -2: return finished(code, false)
        let elapsed = with_clock_nanos() - start
        if elapsed >= deadline:
            // The runtime's timed wait, already past due, kills the child's
            // process group (TERM, then KILL) and reaps it.
            let _ = with_exec_wait(pid, 1)
            return finished(-1, true)
        // Poll at a thousandth of the time run so far, between 20 µs and 1 ms.
        var nap = elapsed / 1000
        if nap < 20000: nap = 20000
        if nap > 1000000: nap = 1000000
        let _ = with_nanosleep(nap)
    finished(-1, false)

/// Run an argument vector from the directory `cwd`, with its stdout and
/// stderr written to the named files, and wait for it however long it runs.
pub fn run_to_files_in(cwd: &str, argv: &List[str], stdout_path: &str, stderr_path: &str) -> Finished:
    finished(with_exec_argv_capture_cwd(argv_blob(argv), stdout_path, stderr_path, 0, cwd), false)

// The peak comes from the reap; a child never reaped (-1, or killed at its
// timeout) has none to report.
fn finished(code: i32, timed_out: bool): Finished { code, timed_out, peak_rss: if code == -1: 0 else: with_exec_child_maxrss() }

/// An argv-based command wrapper.
pub type Command  {
    args: List[str],
}

/// Create a Command from a program path or name.
pub fn command(program: str) -> Command:
    var argv: List[str] = List.new()
    argv.push(program)
    Command { args: argv }

/// Append one argument and return the updated command.
impl Command:
    pub fn arg(arg: str) -> Command:
        var argv: List[str] = List.new()
        for i in 0..self.args.len() as i32:
            argv.push(with_str_clone_ref(self.args[i]))
        argv.push(arg)
        Command { args: argv }

    /// Run the command. Returns the exit status.
    pub fn run() -> i32: run(&self.args)

    /// Run the command and return its exit status.
    pub fn status() -> i32: run(&self.args)
