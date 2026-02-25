// std.random — lightweight random helpers.
//
// Wraps libc rand/srand for deterministic and ad-hoc randomness.

use c_import("#include <stdlib.h>")
extern fn with_time_now() -> i64

pub fn seed(seed_value: i32) -> void =
    srand(seed_value)

pub fn seed_now() -> void =
    srand(with_time_now())

pub fn next_i32() -> i32 =
    rand()

pub fn range_i32(lo: i32, hi: i32) -> i32 =
    if hi <= lo then lo
    else lo + (rand() % (hi - lo))

pub fn chance(percent: i32) -> bool =
    if percent <= 0 then false
    else if percent >= 100 then true
    else (rand() % 100) < percent
