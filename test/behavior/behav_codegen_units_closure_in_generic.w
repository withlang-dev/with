//! env: WITH_CODEGEN_UNITS=8
//! expect-stdout: ok

// #2618 (#681 units): a closure written inside a generic function is
// reached only through the value the function builds, so its symbol is
// internal to the unit that emits it. Left external, every unit but the
// first stripped its body (unit_demote_foreign_definitions) and an instance
// placed in a later unit linked against an undefined `___closure`. Enough
// bodies here for the partition to spread them; `List[str].sort()` is the
// shape the compiler itself tripped on.

use std.algorithms

fn compare_of[T: Ord](sample: &T) -> fn(&T, &T) -> i32:
    (a, b) => if a < b: -1 else if a > b: 1 else: 0

fn pad_a(n: i32) -> i32:
    var s = 0
    for i in 0..n: s = s + i
    s
fn pad_b(n: i32) -> i32:
    var s = 1
    for i in 1..n: s = s * 2 % 1000003
    s
fn pad_c(n: i32) -> i32: pad_a(n) + pad_b(n)
fn pad_d(n: i32) -> i32: pad_c(n) - pad_a(n)
fn pad_e(n: i32) -> i32: pad_d(n) + 1
fn pad_f(n: i32) -> i32: pad_e(n) * 2
fn pad_g(n: i32) -> i32: pad_f(n) - 3

fn strings_compare() -> i32:
    let c = compare_of(&"m")
    c(&"a", &"b") + c(&"b", &"a") * 10 + c(&"a", &"a") * 100

fn ints_compare() -> i32:
    let c = compare_of(&0)
    c(&1, &2) + c(&2, &1) * 10

fn sorted_words() -> List[str]:
    var xs: List[str] = ["pear", "apple", "fig"]
    xs.sort()
    xs

fn sorted_numbers() -> List[i64]:
    var xs: List[i64] = [3, 1, 2]
    xs.sort()
    xs

fn main:
    assert(pad_g(10) > 0)
    assert(strings_compare() == 9)
    assert(ints_compare() == 9)
    assert(sorted_words() == ["apple", "fig", "pear"])
    assert(sorted_numbers() == [1, 2, 3])
    print("ok")
