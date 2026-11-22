//! check-only
// Check-only: the header's functions have no definition to link against. A
// function wrongly made `-> Never` makes the statement after its call
// unreachable; one wrongly left returning fails a `-> Never` body.

use c_import("behav_c_import_noreturn_probe.h")

fn touches -> i32:
    nr_touch(1)
    nr_touch_nothrow(2)
    var q = nr_touch_record_p_anon { q: 3 }
    unsafe { nr_touch_record(&raw mut q) }
    q.q

fn stops_gnu -> Never: nr_stop_gnu(1)
fn stops_gnu_reserved -> Never: nr_stop_gnu_reserved(2)
fn stops_c11 -> Never: nr_stop_c11()

fn main:
    let k = touches()
    if k == -1: stops_gnu()
    if k == -2: stops_gnu_reserved()
    if k == -3: stops_c11()
    print(f"{k}")
