//! time probe 1: Duration constructors are pure ms arithmetic.
use std.time

fn main:
    assert(Duration.millis(500) == 500)
    assert(Duration.from_millis(250) == 250)
    assert(Duration.seconds(2) == 2000)
    assert(Duration.from_secs(3) == 3000)
    assert(Duration.minutes(2) == 120000)
    print("ok")
