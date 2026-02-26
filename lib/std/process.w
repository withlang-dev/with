// std.process — Process utility functions
//
// Provides process-level operations wrapping C stdlib.

extern fn exit(code: i32) -> void
extern fn getpid() -> i32
extern fn system(cmd: *const i8) -> i32
extern fn with_arg_count() -> i32
extern fn with_arg_at(idx: i32) -> str
extern fn with_getenv_str(name: str) -> str
extern fn with_setenv_str(name: str, value: str) -> i32

// Exit the process with given code
pub fn exit_code(code: i32) -> void:
    exit(code)

// Execute a shell command, returns exit status
pub fn system_cmd(cmd: str) -> i32:
    system(cmd)

// Get the process ID
pub fn pid -> i32:
    getpid()

// Command-line arguments.
pub fn args -> Vec[str]:
    let n = with_arg_count()
    var out: Vec[str] = Vec.new()
    var i = 0
    while i < n:
        out.push(with_arg_at(i))
        i = i + 1
    out

// Environment variable lookup (None when missing or empty string).
pub fn env(name: str) -> ?str:
    let v = with_getenv_str(name)
    if v.len() == 0 then None else Some(v)

// Set environment variable (0 on success).
pub fn set_env(name: str, value: str) -> i32:
    with_setenv_str(name, value)

// Minimal command runner wrapper.
type Command = {
    cmd: str,
}

pub fn command(cmd: str) -> Command:
    Command { cmd: cmd }

fn Command.run(self: Command) -> i32:
    system(self.cmd)

fn Command.status(self: Command) -> i32:
    self.run()
