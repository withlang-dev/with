//! expect-stdout: none
//! expect-stdout: some 3
//! expect-stdout: nested none
//! expect-stdout: nested some 7
//! expect-stdout: direct 5
//! expect-stdout: frees 3

// §16.2b.4: a by-value producer states the field whose NULL means nothing
// was produced, checked when the call returns. `nullable field F` presents
// `Option[R]`; `nonnull field F` presents `R`. The field may be a path
// (`inner.data`). Without the clause a failed load was a live resource
// whose buffer was NULL.
use c_import("void *calloc(unsigned long count, unsigned long size);
void free(void *p);
static int frees;
typedef struct { int *data; int n; } Buf;
typedef struct { Buf inner; int tag; } Wrap;
static inline Buf buf_load(int n) { Buf b; b.n = n; b.data = n > 0 ? (int*)calloc(n, sizeof(int)) : 0; return b; }
static inline Buf buf_make(int n) { Buf b; b.n = n; b.data = (int*)calloc(n, sizeof(int)); return b; }
static inline void buf_free(Buf b) { if (b.data) frees = frees + 1; free(b.data); }
static inline Wrap wrap_load(int n) { Wrap w; w.tag = n; w.inner = buf_load(n); return w; }
static inline void wrap_free(Wrap w) { buf_free(w.inner); }
static inline int freed(void) { return frees; }
")

c contract bufs:
    resource Buffer wraps Buf
        from buf_load, nullable field data
        from buf_make, nonnull field data
        drop buf_free
    resource Wrapped wraps Wrap
        from wrap_load, nullable field inner.data
        drop wrap_free

fn main:
    match buf_load(0):
        Some(_) => print("bad")
        None => print("none")
    match buf_load(3):
        Some(b) => print(f"some {b.n}")
        None => print("bad")
    match wrap_load(0):
        Some(_) => print("bad")
        None => print("nested none")
    match wrap_load(7):
        Some(w) => print(f"nested some {w.tag}")
        None => print("bad")
    let direct = buf_make(5)
    print(f"direct {direct.n}")
    drop(direct)
    print(f"frees {freed()}")
