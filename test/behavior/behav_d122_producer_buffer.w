//! expect-stdout: 4 60
//! expect-stdout: empty 0
//! expect-stdout: ok

// D122 (spec §16.2b.8): a buffer-plus-length input on a producer —
// xmlReadMemory's `(const char *buffer, int size)` — is paired as a lend's
// is, and the constructor takes the slice: `Document.read_memory(bytes)`
// passes its address and its length, and an empty slice passes NULL and 0.
// Before, Sema refused the pairing on "a resource's own operation".
use c_import("#include <stdlib.h>
typedef struct ydoc { int size; int first; } ydoc;
static inline ydoc *ydoc_read_memory(const char *buffer, int size) { ydoc *d = (ydoc *)malloc(sizeof(ydoc)); d->size = size; d->first = size > 0 ? buffer[0] : 0; return d; }
static inline void ydoc_free(ydoc *d) { free(d); }
static inline int ydoc_size(const ydoc *d) { return d->size; }
static inline int ydoc_first(const ydoc *d) { return d->first; }
")

c facade y:
    resource Document wraps *mut ydoc
        from ydoc_read_memory
        drop ydoc_free
    fn ydoc_read_memory
        buffer param 0 len param 1
    fn ydoc_size
        lend
    fn ydoc_first
        lend

fn main:
    let d = Document.read_memory("<a/>".as_bytes()).unwrap()
    print(f"{d.size()} {d.first()}")
    let e = Document.read_memory("".as_bytes()).unwrap()
    print(f"empty {e.size()}")
    print("ok")
