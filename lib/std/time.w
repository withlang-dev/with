// std.time — Time utility functions
//
// Provides basic time operations wrapping C stdlib functions.

extern fn with_time_now() -> i64
extern fn sleep(secs: i32) -> i32
extern fn clock() -> i64

// Get current time in seconds since epoch
pub fn now -> i64:
    with_time_now()

// Sleep for given number of seconds
pub fn sleep_secs(secs: i32) -> i32:
    sleep(secs)

// Get CPU clock ticks (for basic benchmarking)
pub fn clock_ticks -> i64:
    clock()
