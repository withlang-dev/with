// std.process — Process utility functions
//
// Provides process-level operations via the runtime interface.
// No c_import — uses with_* runtime functions.

use std.collections

extern fn rt_exit(code: i32) -> Never
extern fn with_getpid() -> i32
extern fn with_exec_argv(args: str) -> i32
extern fn with_arg_count() -> i32
extern fn with_arg_at(idx: i32) -> str
extern fn with_getenv_str(name: str) -> str
extern fn with_setenv_str(name: str, value: str) -> i32
extern fn with_vec_new_out(v: *mut c_void, elem_size: i64) -> Unit
extern fn with_vec_push_str(v: *mut c_void, val: str) -> Unit
extern fn with_str_len(s: str) -> i64

/// Exit the process with the given status code.
pub fn exit_code(code: i32) -> Never:
    rt_exit(code)

/// Get the current process ID.
pub fn pid -> i32:
    with_getpid()

/// Get command-line arguments as a Vec of strings.
pub fn args -> Vec[str]:
    let n = with_arg_count()
    let out: Vec[str] = Vec{ ptr: 0, len: 0, cap: 0, elem_size: 0 }
    with_vec_new_out((&raw mut out) as *mut c_void, 16)
    var i = 0
    while i < n:
        with_vec_push_str((&raw mut out) as *mut c_void, with_arg_at(i))
        i = i + 1
    out

/// Get an environment variable. Returns "" if not set.
pub fn env(name: str) -> str:
    let v = with_getenv_str(name)
    if with_str_len(v) == 0: "" else: v

/// Set an environment variable. Returns 0 on success.
pub fn set_env(name: str, value: str) -> i32:
    with_setenv_str(name, value)

fn argv_blob(items: Vec[str]) -> str:
    var out = ""
    for i in 0..items.len() as i32:
        out = out ++ items.get(i as i64) ++ "\0"
    out

/// Execute an argument vector. The first item is the program name.
pub fn run(argv: Vec[str]) -> i32:
    with_exec_argv(argv_blob(argv))

/// An argv-based command wrapper.
pub type Command  {
    args: Vec[str],
}

/// Create a Command from a program path or name.
pub fn command(program: str) -> Command:
    var argv: Vec[str] = Vec.new()
    argv.push(program)
    Command { args: argv }

/// Append one argument and return the updated command.
pub fn Command.arg(self: Command, arg: str) -> Command:
    var argv: Vec[str] = Vec.new()
    for i in 0..self.args.len() as i32:
        argv.push(self.args.get(i as i64))
    argv.push(arg)
    Command { args: argv }

/// Run the command. Returns the exit status.
pub fn Command.run(self: Command) -> i32:
    run(self.args)

/// Run the command and return its exit status.
pub fn Command.status(self: Command) -> i32:
    run(self.args)
