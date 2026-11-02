// std.time — durations, instants and sleeping.
//
// Provides time operations via the runtime interface.
// No c_import — uses with_* runtime functions.

use rt.rt_core
use rt.fiber_core

/// A span of time: `i64` nanoseconds on every target (D188). A value with no
/// identity (D111): copied, compared and added like a number, never aliased.
/// `isize` is memory's width and would overflow at 2.1 s on wasm32; a
/// duration is not bounded by memory (D114), so its width is fixed.
@[derive(Eq, Ord, Debug)]
pub type Duration { ns: i64 }

const NS_PER_US: i64 = 1000
const NS_PER_MS: i64 = 1000000
const NS_PER_S: i64 = 1000000000

// Constructors are associated functions (no receiver), so under the D7
// location rule they live at top level (`fn Duration.name`).
pub fn Duration.nanos(n: i64) -> Duration: Duration { ns: n }
pub fn Duration.micros(n: i64) -> Duration: Duration { ns: n * NS_PER_US }
pub fn Duration.millis(n: i64) -> Duration: Duration { ns: n * NS_PER_MS }
pub fn Duration.secs(n: i64) -> Duration: Duration { ns: n * NS_PER_S }
pub fn Duration.minutes(n: i64) -> Duration: Duration { ns: n * 60 * NS_PER_S }
pub fn Duration.hours(n: i64) -> Duration: Duration { ns: n * 3600 * NS_PER_S }
pub fn Duration.zero() -> Duration: Duration { ns: 0 }

impl Duration:
    pub fn as_nanos() -> i64: self.ns
    pub fn as_micros() -> i64: self.ns / NS_PER_US
    pub fn as_millis() -> i64: self.ns / NS_PER_MS
    pub fn as_secs() -> i64: self.ns / NS_PER_S
    pub fn as_secs_f64() -> f64: self.ns / 1e9
    pub fn is_zero() -> bool: self.ns == 0
    pub fn add(other: &Duration) -> Duration: Duration { ns: self.ns + other.ns }
    pub fn sub(other: &Duration) -> Duration: Duration { ns: self.ns - other.ns }
    pub fn mul(k: i64) -> Duration: Duration { ns: self.ns * k }
    pub fn div(k: i64) -> Duration: Duration { ns: self.ns / k }

// `50.millis()`, `2.secs()`: a count of units reads as the spec writes it.
extend isize:
    pub fn nanos() -> Duration: Duration.nanos(self)
    pub fn micros() -> Duration: Duration.micros(self)
    pub fn millis() -> Duration: Duration.millis(self)
    pub fn secs() -> Duration: Duration.secs(self)
    pub fn minutes() -> Duration: Duration.minutes(self)
    pub fn hours() -> Duration: Duration.hours(self)

extend i64:
    pub fn nanos() -> Duration: Duration.nanos(self)
    pub fn micros() -> Duration: Duration.micros(self)
    pub fn millis() -> Duration: Duration.millis(self)
    pub fn secs() -> Duration: Duration.secs(self)
    pub fn minutes() -> Duration: Duration.minutes(self)
    pub fn hours() -> Duration: Duration.hours(self)

extend i32:
    pub fn nanos() -> Duration: Duration.nanos(self)
    pub fn micros() -> Duration: Duration.micros(self)
    pub fn millis() -> Duration: Duration.millis(self)
    pub fn secs() -> Duration: Duration.secs(self)
    pub fn minutes() -> Duration: Duration.minutes(self)
    pub fn hours() -> Duration: Duration.hours(self)

/// A point on the monotonic clock.
@[derive(Eq, Ord, Debug)]
pub type Instant { ns: i64 }

pub fn Instant.now() -> Instant: Instant { ns: with_clock_nanos() }

impl Instant:
    pub fn elapsed() -> Duration: Duration { ns: with_clock_nanos() - self.ns }
    pub fn duration_since(earlier: &Instant) -> Duration: Duration { ns: self.ns - earlier.ns }

/// Get current time in seconds since Unix epoch.
pub fn now -> i64:
    with_time_now()

/// Sleep for the given number of seconds (blocking).
pub fn sleep_secs(secs: i32) -> i32:
    with_nanosleep(secs as i64 * NS_PER_S)

/// Sleep for a Duration. The task is suspended, not its thread: other tasks
/// run while it sleeps (§14.3).
pub async fn sleep(d: Duration): with_fiber_sleep_until(with_clock_nanos() + d.ns)

/// A task that completes after `d`: the `_ = timeout(1.secs())` arm of a
/// `select await` (§14.10).
pub async fn timeout(d: Duration): with_fiber_sleep_until(with_clock_nanos() + d.ns)

/// Get monotonic time in nanoseconds (for benchmarking).
pub fn now_ns() -> i64:
    with_clock_nanos()

/// Get monotonic clock ticks in nanoseconds.
pub fn clock_ticks -> i64:
    with_clock_nanos()
