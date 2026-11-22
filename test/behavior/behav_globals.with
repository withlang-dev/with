//! expect-stdout: ok

// Tests: global variables, global mutation, global access from functions,
//        global initialization

var g_int: i32 = 0
var g_counter: i32 = 0

fn test_global_initial_value:
    assert(g_int == 0)
    assert(g_counter == 0)

fn test_global_mutation:
    g_int = 42
    assert(g_int == 42)
    g_int = 0

fn increment_global:
    g_counter = g_counter + 1

fn test_global_from_function:
    g_counter = 0
    increment_global()
    increment_global()
    increment_global()
    assert(g_counter == 3)

fn get_counter() -> i32:
    g_counter

fn test_global_read_from_function:
    g_counter = 99
    assert(get_counter() == 99)
    g_counter = 0

fn reset_counter:
    g_counter = 0

fn test_global_reset:
    g_counter = 100
    reset_counter()
    assert(g_counter == 0)

var g_accumulator: i32 = 0

fn accumulate(x: i32):
    g_accumulator = g_accumulator + x

fn test_global_accumulate:
    g_accumulator = 0
    accumulate(10)
    accumulate(20)
    accumulate(30)
    assert(g_accumulator == 60)

fn main:
    test_global_initial_value()
    test_global_mutation()
    test_global_from_function()
    test_global_read_from_function()
    test_global_reset()
    test_global_accumulate()
    print("ok")
