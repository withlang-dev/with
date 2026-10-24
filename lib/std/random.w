// std.random — lightweight random helpers.
//
// No c_import — uses a xorshift64 PRNG seeded from the runtime's
// cryptographic random source (arc4random_buf on macOS).

use rt.rt_core

var rng_state: i64 = 0

fn ensure_seeded():
    if rng_state == 0:
        with_fill_random(&rng_state as *mut u8, 8)
        if rng_state == 0:
            rng_state = with_clock_nanos()
        if rng_state == 0:
            rng_state = 1

fn xorshift64() -> i64:
    ensure_seeded()
    var x = rng_state
    x = x ^ (x << 13)
    x = x ^ (x >> 7)
    x = x ^ (x << 17)
    rng_state = x
    x

/// Seed the random number generator with a specific value (for reproducibility).
pub fn seed(seed_value: i32) -> Unit:
    rng_state = seed_value as i64
    if rng_state == 0:
        rng_state = 1

/// Seed the random number generator from the current time.
pub fn seed_now -> Unit:
    with_fill_random(&rng_state as *mut u8, 8)
    if rng_state == 0:
        rng_state = with_clock_nanos()

/// Generate a random i32.
pub fn next_i32 -> i32:
    let v = xorshift64()
    (v >> 16) as i32

// A non-negative draw: the sign bit masked off, never negated (#1058: the
// minimum value negated overflows).
fn positive_i32() -> i32: next_i32() & 2147483647
fn positive_i64() -> i64: xorshift64() & 9223372036854775807

/// Generate a random i32 in the range [lo, hi).
pub fn range_i32(lo: i32, hi: i32) -> i32:
    if hi <= lo: return lo
    lo + (positive_i32() % (hi - lo))

/// Generate a random index in the range [lo, hi) (D108: lengths and
/// indices are `isize`).
pub fn range_isize(lo: isize, hi: isize) -> isize:
    if hi <= lo: return lo
    lo + (positive_i64() % ((hi - lo) as i64)) as isize

/// Return true with the given probability (-100 percent).
pub fn chance(percent: i32) -> bool:
    if percent <= 0: return false
    if percent >= 100: return true
    (positive_i32() % 100) < percent
