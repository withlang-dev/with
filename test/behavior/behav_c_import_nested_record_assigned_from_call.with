//! expect-stdout: 3

// A header's inline function that assigns a record member from a call
// (`w.inner = buf_load(n)`) copies it with the translation's own
// `with_memcpy`, a raw call there since #3218: it was emitted bare, and the
// header was refused ("raw c_import function call requires unsafe context").
use c_import("typedef struct { int a; int n; } Buf;
typedef struct { Buf inner; int tag; } Wrap;
static inline Buf buf_load(int n) { Buf b; b.n = n; b.a = 1; return b; }
static inline Wrap wrap_load(int n) { Wrap w; w.tag = n; w.inner = buf_load(n); return w; }
")

fn main:
    let w = wrap_load(3)
    print(f"{w.inner.n}")
