//! expect-error: (at <c_import source>:2:14)

// An omitted symbol from source text given to c_import inline is located in
// that text, not in the temp file it is parsed from: the random mkstemp name
// made the same diagnostic differ from run to run (sema-order-check).

use c_import("typedef int (*fnptr)(int);\ninline fnptr get_fn(void) { return 0; }\n")

fn main:
    get_fn
