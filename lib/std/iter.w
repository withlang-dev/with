// std.iter — Iterator utility functions.
//
// Helper functions for common iterator patterns.

extern fn with_vec_len(v: &Vec[i32]) -> i64
extern fn with_vec_get_i32(v: &Vec[i32], index: i64) -> i32
extern fn with_vec_get_str(v: &Vec[str], index: i64) -> str
extern fn with_vec_push_i32(v: &Vec[i32], val: i32) -> void
extern fn with_vec_new_out(v: &Vec[i32], elem_size: i64) -> void

pub fn sum(arr: Vec[i32]) -> i32:
    var total: i32 = 0
    var i: i64 = 0
    let n = with_vec_len(&arr)
    while i < n:
        total = total + with_vec_get_i32(&arr, i)
        i = i + 1
    total

pub fn map(arr: Vec[str], f: fn(str) -> i32) -> Vec[i32]:
    let result: Vec[i32] = Vec{ ptr: 0, len: 0, cap: 0, elem_size: 0 }
    with_vec_new_out(&result, 4)
    var i: i64 = 0
    let n = with_vec_len(&arr)
    while i < n:
        let x = with_vec_get_str(&arr, i)
        let y = f(x)
        with_vec_push_i32(&result, y)
        i = i + 1
    result

pub fn filter(arr: Vec[i32], pred: fn(i32) -> bool) -> Vec[i32]:
    let result: Vec[i32] = Vec{ ptr: 0, len: 0, cap: 0, elem_size: 0 }
    with_vec_new_out(&result, 4)
    var i: i64 = 0
    let n = with_vec_len(&arr)
    while i < n:
        let x = with_vec_get_i32(&arr, i)
        if pred(x):
            with_vec_push_i32(&result, x)
        i = i + 1
    result

pub fn count[T](arr: [T]) -> i32:
    arr.len

pub fn contains(arr: [i32], target: i32) -> bool:
    for x in arr:
        if x == target then return true
    false
