//! expect-check-fail: unknown domain 'locale'

// D30: compiled in-unit, the runtime's own `libc` facade declares errno,
// environ and locale. A program facade naming a domain it never declares is
// still told it is unknown, as with the object-linked runtime it never sees;
// declared in both, the two are one domain (ruling §35).
use c_import("int db_count(void* d);\n")

c facade dbl:
    fn db_count
        preserves domain locale

fn main:
    print("ok")
