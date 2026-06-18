//! expect-error: raw c_import function call requires unsafe context

// #603 / #379: borrowed nullable-pointer returns are modeled ONLY for curated
// overlay symbols. A pointer-returning c_import function that is NOT in the
// overlay stays raw and requires `unsafe` to call -- there is no blanket
// "nullable pointer return is safe" rule (that would be guessing, not
// evidence). `mychr` is uncurated, so this call must require unsafe.

use c_import("char *mychr(const char *s, int c);\n")

fn main:
    let p = mychr("hi", 105)
    print("unreachable")
