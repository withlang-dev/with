// lib/test/testing — With test framework adapter over Unity C
//
// Provides assertion functions for writing tests.
// Uses __FILE__ and __LINE__ defaults for automatic location tracking.

use c_import("#include <stdio.h>")
use c_import("#include <stdlib.h>")
use c_import("#include <string.h>")
use std.process

// ── Assertion Functions ─────────────────────────────────────────

// Assert a condition is true.
pub fn assert_true(condition: bool, msg: str = "assertion failed", file: str = __FILE__, line: u32 = __LINE__) -> void:
    if not condition:
        print("[FAIL] ")
        print(msg)
        print(" at ")
        print(file)
        print(":")
        println(line)
        exit_code(1)

// Assert a condition is false.
pub fn assert_false(condition: bool, msg: str = "expected false", file: str = __FILE__, line: u32 = __LINE__) -> void:
    assert_true(not condition, msg, file, line)

// Assert two i32 values are equal.
pub fn assert_eq_i32(left: i32, right: i32, file: str = __FILE__, line: u32 = __LINE__) -> void:
    if left != right:
        print("[FAIL] expected ")
        print(left)
        print(" == ")
        print(right)
        print(" at ")
        print(file)
        print(":")
        println(line)
        exit_code(1)

// Assert two i32 values are not equal.
pub fn assert_ne_i32(left: i32, right: i32, file: str = __FILE__, line: u32 = __LINE__) -> void:
    if left == right:
        print("[FAIL] expected ")
        print(left)
        print(" != ")
        print(right)
        print(" at ")
        print(file)
        print(":")
        println(line)
        exit_code(1)

// Assert two i64 values are equal.
pub fn assert_eq_i64(left: i64, right: i64, file: str = __FILE__, line: u32 = __LINE__) -> void:
    if left != right:
        print("[FAIL] expected ")
        print(left)
        print(" == ")
        print(right)
        print(" at ")
        print(file)
        print(":")
        println(line)
        exit_code(1)

// Assert two f64 values are equal (exact).
pub fn assert_eq_f64(left: f64, right: f64, file: str = __FILE__, line: u32 = __LINE__) -> void:
    if left != right:
        print("[FAIL] expected ")
        print(left)
        print(" == ")
        print(right)
        print(" at ")
        print(file)
        print(":")
        println(line)
        exit_code(1)

// Assert two bool values are equal.
pub fn assert_eq_bool(left: bool, right: bool, file: str = __FILE__, line: u32 = __LINE__) -> void:
    if left != right:
        print("[FAIL] expected equal bools at ")
        print(file)
        print(":")
        println(line)
        exit_code(1)

// Assert two str values are equal.
pub fn assert_eq_str(left: str, right: str, file: str = __FILE__, line: u32 = __LINE__) -> void:
    let result: i32 = strcmp(left, right)
    if result != 0:
        print("[FAIL] expected \"")
        print(left)
        print("\" == \"")
        print(right)
        print("\" at ")
        print(file)
        print(":")
        println(line)
        exit_code(1)

// Assert a value is less than another.
pub fn assert_lt_i32(left: i32, right: i32, file: str = __FILE__, line: u32 = __LINE__) -> void:
    if not (left < right):
        print("[FAIL] expected ")
        print(left)
        print(" < ")
        print(right)
        print(" at ")
        print(file)
        print(":")
        println(line)
        exit_code(1)

// Assert a value is greater than another.
pub fn assert_gt_i32(left: i32, right: i32, file: str = __FILE__, line: u32 = __LINE__) -> void:
    if not (left > right):
        print("[FAIL] expected ")
        print(left)
        print(" > ")
        print(right)
        print(" at ")
        print(file)
        print(":")
        println(line)
        exit_code(1)

// Unconditional test failure with a message.
pub fn fail(msg: str = "test failed", file: str = __FILE__, line: u32 = __LINE__) -> void:
    print("[FAIL] ")
    print(msg)
    print(" at ")
    print(file)
    print(":")
    println(line)
    exit_code(1)

// Returns true when `with test -short` is enabled.
pub fn short() -> bool:
    match env("WITH_TEST_SHORT")
        Some(_) -> true
        None -> false

// Mark the current test as skipped.
pub fn skip(msg: str = "skipped") -> void:
    print("__WITH_TEST_SKIP__ ")
    println(msg)
    exit_code(0)
