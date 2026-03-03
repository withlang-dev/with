// std.iter — Iterator utility functions.
//
// Helper functions for common iterator patterns.

pub fn sum(arr: [i32]) -> i32:
    var total = 0
    for x in arr:
        total = total + x
    total

pub fn count[T](arr: [T]) -> i32:
    arr.len

pub fn contains(arr: [i32], target: i32) -> bool:
    for x in arr:
        if x == target then return true
    false
