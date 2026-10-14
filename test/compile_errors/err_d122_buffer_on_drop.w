//! expect-check-fail: fn 'ydoc_release': a buffer pairing describes a lend, a free operation or a producer, and 'ydoc_release' is a resource's own lifecycle operation (its initializer, drop or destroyer); a slice in that rendering is not modeled (§16.2b.8)

// D122 (spec §16.2b.8): a producer may pair a buffer with its length (the
// constructor takes the slice, behav_d122_producer_buffer); an
// initializer, drop or destroyer still takes only what the resource
// passes it.
use c_import("#include <stdlib.h>
typedef struct ydoc { int size; } ydoc;
static inline ydoc *ydoc_read_memory(const char *buffer, int size) { ydoc *d = (ydoc *)malloc(sizeof(ydoc)); d->size = size; return d; }
static inline void ydoc_release(ydoc *d, const char *note, int len) { free(d); }
")

c facade y:
    resource Document wraps *mut ydoc
        from ydoc_read_memory
        drop ydoc_release
    fn ydoc_read_memory
        buffer param 0 len param 1
    fn ydoc_release
        buffer param 1 len param 2

fn main:
    let d = Document.read_memory("<a/>".as_bytes()).unwrap()
    print(f"{d.size}")
