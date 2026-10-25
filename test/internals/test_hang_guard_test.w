//! expect-stdout: ok
// #2362: `with test` stops a test binary only at a hang guard, never at a
// speed budget. The fixed 120 s limit killed a passing 160 s test on a slow
// host and reported it as a run failure.
use BuildGraphSupport

fn main:
    assert(TEST_HANG_GUARD_MS >= 30 * 60 * 1000)
    print("ok")
