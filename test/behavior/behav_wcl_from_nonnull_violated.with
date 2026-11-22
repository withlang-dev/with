//! expect-exit: 134
//! expect-stderr: box_new: the contract states 'from box_new, nonnull', and C returned NULL

// §31.8.2: under `from f, nonnull` a NULL return is a contract failure
// naming the producer, so a resource over NULL never exists.
use c_import("void free(void *p);
typedef struct { int n; } box;
static inline box *box_new(int n) { return 0; }
static inline void box_free(box *b) { free(b); }
")

c contract boxes:
    resource Crate wraps *mut box
        from box_new, nonnull
        drop box_free

fn main:
    let b = Crate.new(7)
    print("unreachable")
