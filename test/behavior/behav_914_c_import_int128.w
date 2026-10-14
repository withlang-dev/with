//! expect-stdout: 1267650600228229401496703205381
//! expect-stdout: -5

// #914: __int128 round-trips through c_import at full width — the C side
// adds past 2^64 and the With side prints every digit.
use c_import("static inline __int128 add128(__int128 a, __int128 b) { return a + b; }\nstatic inline __int128 neg128(__int128 a) { return -a; }\n")

fn main:
    let pow100: i128 = 1267650600228229401496703205376
    print(add128(pow100, 5))
    print(neg128(5))
