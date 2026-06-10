//! check-only
// Regression helper for issue #113.

extern var issue113_shared_counter: i32

pub fn issue113_read_shared() -> i32:
    issue113_shared_counter

pub fn issue113_write_shared(value: i32) -> void:
    issue113_shared_counter = value
