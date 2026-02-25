// std.hash — pure-With hash helpers.
//
// Provides deterministic 64-bit hash utilities for common scalar inputs.

pub fn combine(seed: i64, value: i64) -> i64 =
    (seed * 1099511628211) ^ value

pub fn hash_i64(value: i64) -> i64 =
    combine(1469598103934665603, value)

pub fn hash_pair(a: i64, b: i64) -> i64 =
    combine(hash_i64(a), b)

pub fn hash_str(s: str) -> i64 =
    var h: i64 = 1469598103934665603
    var i: i64 = 0
    while i < s.len():
        h = combine(h, s[i])
        i = i + 1
    h
