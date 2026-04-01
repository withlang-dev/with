// std.random — lightweight random helpers.
//
// No c_import — uses a xorshift64 PRNG seeded from the runtime's
// cryptographic random source (arc4random_buf on macOS).

extern fn with_fill_random(buf: *mut u8, len: i64) -> void
extern fn with_clock_nanos() -> i64

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
pub fn seed(seed_value: i32) -> void:
    rng_state = seed_value as i64
    if rng_state == 0:
        rng_state = 1

/// Seed the random number generator from the current time.
pub fn seed_now -> void:
    with_fill_random(&rng_state as *mut u8, 8)
    if rng_state == 0:
        rng_state = with_clock_nanos()

/// Generate a random i32.
pub fn next_i32 -> i32:
    let v = xorshift64()
    (v >> 16) as i32

/// Generate a random i32 in the range [lo, hi).
pub fn range_i32(lo: i32, hi: i32) -> i32:
    if hi <= lo: return lo
    let range = hi - lo
    let v = next_i32()
    let positive = if v < 0: 0 - v else: v
    lo + (positive % range)

/// Return true with the given probability (0-100 percent).
pub fn chance(percent: i32) -> bool:
    if percent <= 0: return false
    if percent >= 100: return true
    let v = next_i32()
    let positive = if v < 0: 0 - v else: v
    (positive % 100) < percent
