//! expect-check-fail: a value record is flat, and field 'p'
// D198 (§16.2b.5): a pointer in a union member is the same pointer; safe
// code writes it through the integer member.
use c_import("typedef union { const int *p; long n; } Either; static inline int either_first(const Either *e) { return *e->p; }")

c facade eithers:
    fn either_first
        reads param e

fn main:
    print("unreachable")
