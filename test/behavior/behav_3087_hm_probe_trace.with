//! env: WITH_TRACE_HM_PROBES=1
//! expect-stdout: 2858
//! expect-stderr: hm-probes: lookups=24999
//! expect-stderr: hm-probes: by key kind (kind lookups slots/lookup): bytes 24999
// #3087: WITH_TRACE_HM_PROBES=1 counts the index slots every map lookup
// reads and reports them at exit (totals, a histogram, by key kind, and the
// maps that read most), so a probe-heavy map is measured, not guessed at.
use std.collections.HashMap

fn main:
    var m = HashMap[i32, i32].new()
    for i in 0..5000: m.insert(i * 7, i)
    var hits = 0
    for i in 0..20000: if m.contains(i): hits = hits + 1
    print(f"{hits}")
