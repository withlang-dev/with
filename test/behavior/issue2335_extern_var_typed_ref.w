//! check-only
// Regression helper for #2335.

extern var issue2335_shared_counter: i32

pub fn issue2335_read_shared() -> i32: issue2335_shared_counter

pub fn issue2335_write_shared(value: i32): issue2335_shared_counter = value
