// std.signal — minimal signal constants and helpers.
//
// No c_import — uses with_* runtime functions.

extern fn with_raise(sig: i32) -> i32

/// SIGINT signal number (interrupt, Ctrl+C).
pub fn sigint -> i32:
    2

/// SIGTERM signal number (termination request).
pub fn sigterm -> i32:
    15

/// SIGKILL signal number (forced kill, cannot be caught).
pub fn sigkill -> i32:
    9

/// Send a signal to the current process.
pub fn raise_signal(sig: i32) -> i32:
    with_raise(sig)
