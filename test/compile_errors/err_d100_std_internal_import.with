//! expect-check-fail: module 'std.internal.str_abi' is internal to the standard library (§18.3)

// D100 (§18.3): a module under an `internal` path segment is importable
// only from inside its parent's tree. std.internal is the standard
// library's: std's own modules import it (std.tls, std.http, std.crypto),
// a user program cannot.
use std.internal.str_abi

fn main:
    print("unreachable")
