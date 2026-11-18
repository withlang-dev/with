//! expect-stdout: both: true true

// D208 (§16.2b.7; Eric, 2026-11-18): `getenv` is no writer of the
// environment. POSIX.1-2024 requires the pointer it returns to point into
// the environment data itself, so a second `getenv` leaves the first view
// alone. C11 alone would let an implementation reuse one buffer; no target
// With supports does.

use c_import("char *getenv(const char *name);\n")

fn main:
    let first = getenv("PATH")
    let second = getenv("PATH")
    print(f"both: {first.is_some()} {second.is_some()}")
