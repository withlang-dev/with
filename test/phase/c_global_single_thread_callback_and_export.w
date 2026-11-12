//! expect-check-stdout: ok

// §16.3 (#3220): a callback C invokes and an exported function C calls run
// on a thread where the program calls into C. They are no concurrency of
// the program's own, so a program without tasks reads and writes a C
// global with no `unsafe` (examples/c-interop reads `tally_calls` so).
use c_import("int g_n; static inline void each(void (*cb)(int)) { cb(1); }")

// §31.6.2: the library is the test's own, and its contract says it runs no
// threads; without that its global is raw.
c facade lib:
    runs no threads

@[c_export("my_score")]
fn score(v: i32) -> i32: v

fn note(v: i32): print(f"{v}")

fn main:
    unsafe { each(note) }
    g_n = g_n + 1
    print(f"{g_n}")
