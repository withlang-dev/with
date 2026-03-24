// std.process — Process utility functions
//
// Provides process-level operations wrapping C stdlib.

use std.collections

extern fn exit(code: i32) -> void
extern fn getpid() -> i32
extern fn system(cmd: *const i8) -> i32
extern fn with_arg_count() -> i32
extern fn with_arg_at(idx: i32) -> str
extern fn with_getenv_str(name: str) -> str
extern fn with_setenv_str(name: str, value: str) -> i32
extern fn with_vec_new_out(v: *void, elem_size: i64) -> void
extern fn with_vec_push_str(v: *void, val: str) -> void
extern fn with_str_len(s: str) -> i64
// Exit the process with given code
pub fn exit_code(code: i32) -> void:
    exit(code)

// Execute a shell command, returns exit status
pub fn system_cmd(cmd: str) -> i32:
    system(cmd as *const i8)

// Get the process ID
pub fn pid -> i32:
    getpid()

// Command-line arguments.
pub fn args -> Vec[str]:
    let n = with_arg_count()
    let out: Vec[str] = Vec{ ptr: 0, len: 0, cap: 0, elem_size: 0 }
    with_vec_new_out(&out, 16)
    var i = 0
    while i < n:
        with_vec_push_str(&out, with_arg_at(i))
        i = i + 1
    out

// Environment variable lookup (empty string when missing).
pub fn env(name: str) -> str:
    let v = with_getenv_str(name)
    if with_str_len(v) == 0 then "" else v

// Set environment variable (0 on success).
pub fn set_env(name: str, value: str) -> i32:
    with_setenv_str(name, value)

// Minimal command runner wrapper.
type Command  {
    cmd: str,
}

pub fn command(cmd: str) -> Command:
    Command { cmd: cmd }

fn Command.run(self: Command) -> i32:
    system(self.cmd as *const i8)

fn Command.status(self: Command) -> i32:
    system(self.cmd as *const i8)
