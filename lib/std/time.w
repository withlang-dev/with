// std.time — Time utility functions
//
// Provides time operations via the runtime interface.
// No c_import — uses with_* runtime functions.

extern fn with_time_now() -> i64
extern fn with_clock_nanos() -> i64
extern fn with_nanosleep(ns: i64) -> i32
extern fn with_usleep(usecs: i32) -> i32

/// A duration in milliseconds.
type Duration = i32

extend Duration:
    /// Create a Duration from milliseconds.
    fn millis(ms: i32) -> Duration:
        ms

    /// Create a Duration from milliseconds.
    fn from_millis(ms: i32) -> Duration:
        ms

    /// Create a Duration from seconds.
    fn seconds(secs: i32) -> Duration:
        secs * 1000

    /// Create a Duration from seconds.
    fn from_secs(secs: i32) -> Duration:
        secs * 1000

    /// Create a Duration from minutes.
    fn minutes(mins: i32) -> Duration:
        mins * 60 * 1000

/// Get current time in seconds since Unix epoch.
pub fn now -> i64:
    with_time_now()

/// Sleep for the given number of seconds (blocking).
pub fn sleep_secs(secs: i32) -> i32:
    with_nanosleep(secs as i64 * 1000000000)

/// Sleep for a Duration (async-compatible).
pub async fn sleep(d: Duration) -> i32:
    with_nanosleep(d as i64 * 1000000)

/// Get monotonic time in nanoseconds (for benchmarking).
pub fn now_ns() -> i64:
    with_clock_nanos()

/// Get monotonic clock ticks in nanoseconds.
pub fn clock_ticks -> i64:
    with_clock_nanos()
