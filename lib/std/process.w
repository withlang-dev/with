// std.process — Process utility functions
//
// Provides process-level operations wrapping C stdlib.

extern fn exit(code: i32) -> void
extern fn getpid() -> i32
extern fn system(cmd: *const i8) -> i32

// Exit the process with given code
pub fn exit_code(code: i32) -> void =
    exit(code)

// Execute a shell command, returns exit status
pub fn system_cmd(cmd: str) -> i32 =
    system(cmd)

// Get the process ID
pub fn pid() -> i32 =
    getpid()
