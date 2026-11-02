//! expect-stdout: 50000000 2000000000 true
//! expect-stdout: 2050 3 1.5
//! expect-stdout: true true
//! expect-stdout: ok

// D188: Duration is a value over i64 nanoseconds; `50.millis()` reads as
// §14 writes it (the lexer takes a dot after digits as a member access
// unless a digit follows, §30 FLOAT_LIT); arithmetic and comparison are a
// number's; Instant measures the monotonic clock; sleep takes a Duration.

use std.time

async fn nap(d: Duration) -> i64:
    sleep(d).await
    d.as_millis()

async fn main:
    let a = 50.millis()
    let b = 2.secs()
    print(f"{a.as_nanos()} {b.as_nanos()} {a < b}")
    let total = a + b
    let n: i32 = 3
    let c = n.millis()
    print(f"{total.as_millis()} {c.as_millis()} {Duration.millis(1500).as_secs_f64()}")
    let start = Instant.now()
    let slept = nap(1.millis()).await
    let elapsed = start.elapsed()
    print(f"{slept == 1} {elapsed >= 1.millis()}")
    print("ok")
