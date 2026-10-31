//! expect-error: unsafe

// D172 (§19.1): constructing the marker type directly is `unsafe`.
use std.memo

fn main:
    let cell = Interior.new(5)
