//! expect-error: raw pointer dereference requires unsafe context

// §31.4: a pointer return is inert. `mychr` has no contract, so the call is
// safe and what it returns is a raw pointer: nothing says it is text, that
// it is non-null or how long it lives (#603: no blanket "nullable pointer
// return is modeled" rule), so reading through it needs `unsafe`.

use c_import("char *mychr(const char *s, int c);\n")

fn main:
    let p = mychr("hi", 105)
    let c = *p
    print("unreachable")
