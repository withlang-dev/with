//! expect-check-fail: 'stream.zeroed()' is not available: field 'notify' (

// §16.2b.3: `zeroed()` is safe only when all-zero bits are a value of every
// field's With type. A C function-pointer field imports as a non-null
// `extern "C" fn`, which has no all-zero value, so the record has no
// `zeroed()`; the refusal names the field.
use c_import("struct stream { int state; void (*notify)(int); };")

fn main:
    let s = stream.zeroed()
    print(s.state)
