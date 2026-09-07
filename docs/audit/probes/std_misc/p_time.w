use std.time

fn expect(label: str, ok: bool):
    if ok:
        print(f"PASS: {label}\n")
    else:
        print(f"FAIL: {label}\n")

fn main():
    // now() sanity: positive epoch seconds
    let t = now()
    expect("now positive", t > 1700000000)
    // monotonic clock non-decreasing
    let a = now_ns()
    let b = now_ns()
    expect("now_ns non-decreasing", b >= a)
    expect("now_ns positive", b > 0)
    let c = clock_ticks()
    expect("clock_ticks positive", c > 0)
    // sleep_secs(0) returns without long block
    let r = sleep_secs(0)
    expect("sleep_secs(0) rc", r == 0)
    let t2 = now()
    expect("now non-decreasing", t2 >= t)
