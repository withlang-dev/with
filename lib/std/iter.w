// std.iter — Iterator utility functions.
//
// Helper functions for common iterator patterns.

use std.collections

extern fn with_vec_len(v: *mut c_void) -> i64
extern fn with_vec_get_i32(v: *mut c_void, index: i64) -> i32
extern fn with_vec_get_str(v: *mut c_void, index: i64) -> str
extern fn with_vec_push_i32(v: *mut c_void, val: i32) -> Unit
extern fn with_vec_new_out(v: *mut c_void, elem_size: i64) -> Unit

/// Sum all elements in a Vec[i32].
pub fn sum(arr: Vec[i32]) -> i32:
    var total: i32 = 0
    var i: i64 = 0
    let n = with_vec_len((&raw mut arr) as *mut c_void)
    while i < n:
        total = total + with_vec_get_i32((&raw mut arr) as *mut c_void, i)
        i = i + 1
    total

/// Apply a function to each element, returning a new Vec of results.
pub fn map(arr: Vec[str], f: fn(str) -> i32) -> Vec[i32]:
    let result: Vec[i32] = Vec{ ptr: 0, len: 0, cap: 0, elem_size: 0 }
    with_vec_new_out((&raw mut result) as *mut c_void, 4)
    var i: i64 = 0
    let n = with_vec_len((&raw mut arr) as *mut c_void)
    while i < n:
        let x = with_vec_get_str((&raw mut arr) as *mut c_void, i)
        let y = f(x)
        with_vec_push_i32((&raw mut result) as *mut c_void, y)
        i = i + 1
    result

/// Keep only elements where `pred` returns true.
pub fn filter(arr: Vec[i32], pred: fn(i32) -> bool) -> Vec[i32]:
    let result: Vec[i32] = Vec{ ptr: 0, len: 0, cap: 0, elem_size: 0 }
    with_vec_new_out((&raw mut result) as *mut c_void, 4)
    var i: i64 = 0
    let n = with_vec_len((&raw mut arr) as *mut c_void)
    while i < n:
        let x = with_vec_get_i32((&raw mut arr) as *mut c_void, i)
        if pred(x):
            with_vec_push_i32((&raw mut result) as *mut c_void, x)
        i = i + 1
    result

/// Return the number of elements in an array.
pub fn count[T](arr: [T]) -> i32:
    arr.len

/// Return true if `target` is in the array.
pub fn contains(arr: [i32], target: i32) -> bool:
    for x in arr:
        if x == target: return true
    false

/// Sum all elements from a VecIter[i32].
pub fn iter_sum(iter: VecIter[i32]) -> i32:
    var total = 0
    var done = false
    while not done:
        let item = iter.next()
        if item.is_some():
            total = total + item.unwrap()
        else:
            done = true
    total
