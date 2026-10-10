//! check-only
// Regression helper for issue #113.

extern var issue113_shared_counter: isize

pub fn issue113_read_shared() -> isize:
    issue113_shared_counter

pub fn issue113_write_shared(value: isize):
    issue113_shared_counter = value
