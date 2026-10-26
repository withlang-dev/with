// std.random — lightweight random helpers.
//
// No c_import — uses a xorshift64 PRNG seeded from the runtime's
// cryptographic random source (arc4random_buf on macOS). A draw has the
// type its use demands (#2279): `let b: u8 = next()`, `range(0, hi)` with
// an `i64` bound draws an `i64`.

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
pub fn seed(value: u64):
    rng_state = value as i64
    if rng_state == 0:
        rng_state = 1

/// Seed the random number generator from the current time.
pub fn seed_now:
    with_fill_random(&rng_state as *mut u8, 8)
    if rng_state == 0:
        rng_state = with_clock_nanos()

/// A type std.random draws: `random_any` is any value of the type (a float
/// is uniform in [0, 1)), `random_in` is uniform in [lo, hi), and `lo` when
/// `hi <= lo`. Implement it to make another type drawable.
pub trait Random:
    fn random_any() -> Self
    fn random_in(lo: Self, hi: Self) -> Self

/// A random value of the type its use demands: `let b: u8 = next()`.
pub fn next[T: Random]() -> T: T.random_any()

/// A random value in [lo, hi) of the bounds' type; `lo` when `hi <= lo`.
pub fn range[T: Random](lo: T, hi: T) -> T: T.random_in(lo, hi)

/// Return true with the given probability (0-100 percent).
pub fn chance(percent: i32) -> bool:
    if percent <= 0: return false
    if percent >= 100: return true
    let roll: i32 = range(0, 100)
    roll < percent

// 64 random bits; a narrower draw takes the high ones, xorshift's best.
fn bits() -> u64: xorshift64() as u64

// Uniform in [lo, hi) over the 64-bit two's-complement circle: `hi - lo`
// fits a u64 whatever the signs, so every integer type draws through these.
fn signed_in(lo: i64, hi: i64) -> i64:
    if hi <= lo: return lo
    ((lo as u64) +% bits() % ((hi as u64) -% (lo as u64))) as i64
fn unsigned_in(lo: u64, hi: u64) -> u64:
    if hi <= lo: return lo
    lo + bits() % (hi - lo)

// Uniform in [0, 1): the high 53 bits over 2^53.
fn unit() -> f64: (bits() >> 11) as f64 / 9007199254740992.0

impl Random for i8:
    fn random_any() -> i8: (bits() >> 56) as i8
    fn random_in(lo: i8, hi: i8) -> i8: signed_in(lo, hi) as i8
impl Random for i16:
    fn random_any() -> i16: (bits() >> 48) as i16
    fn random_in(lo: i16, hi: i16) -> i16: signed_in(lo, hi) as i16
impl Random for i32:
    fn random_any() -> i32: (bits() >> 32) as i32
    fn random_in(lo: i32, hi: i32) -> i32: signed_in(lo, hi) as i32
impl Random for i64:
    fn random_any() -> i64: bits() as i64
    fn random_in(lo: i64, hi: i64) -> i64: signed_in(lo, hi)
impl Random for isize:
    fn random_any() -> isize: bits() as isize
    fn random_in(lo: isize, hi: isize) -> isize: signed_in(lo, hi) as isize
impl Random for u8:
    fn random_any() -> u8: (bits() >> 56) as u8
    fn random_in(lo: u8, hi: u8) -> u8: unsigned_in(lo, hi) as u8
impl Random for u16:
    fn random_any() -> u16: (bits() >> 48) as u16
    fn random_in(lo: u16, hi: u16) -> u16: unsigned_in(lo, hi) as u16
impl Random for u32:
    fn random_any() -> u32: (bits() >> 32) as u32
    fn random_in(lo: u32, hi: u32) -> u32: unsigned_in(lo, hi) as u32
impl Random for u64:
    fn random_any() -> u64: bits()
    fn random_in(lo: u64, hi: u64) -> u64: unsigned_in(lo, hi)
impl Random for usize:
    fn random_any() -> usize: bits() as usize
    fn random_in(lo: usize, hi: usize) -> usize: unsigned_in(lo, hi) as usize
impl Random for f64:
    fn random_any() -> f64: unit()
    fn random_in(lo: f64, hi: f64) -> f64:
        if not (hi > lo): return lo
        let v = lo + (hi - lo) * unit()
        // Rounding can land on `hi`; the interval is half-open.
        if v < hi: v else: lo
impl Random for f32:
    fn random_any() -> f32: (bits() >> 40) as f32 / 16777216.0
    fn random_in(lo: f32, hi: f32) -> f32:
        if not (hi > lo): return lo
        let u: f32 = next()
        let v = lo + (hi - lo) * u
        if v < hi: v else: lo
