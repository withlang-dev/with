//! expect-check-fail: handle 'Anything' wraps *mut c_void; a callback-scope handle wraps the pointer to a C record

// Spec §16.2b.9 (ruling Amendment 1, #1611): a handle wraps the pointer to
// the C record a callback is passed (`*mut sqlite3_context`) — never
// `void *`, which every pointer converts to.
use c_import("void use_it(void *p);\n")

c facade loose:
    handle Anything wraps *mut c_void

fn main:
    print("unreachable")
