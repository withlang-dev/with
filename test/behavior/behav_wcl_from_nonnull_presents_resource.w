//! expect-stdout: 7
//! expect-stdout: ok

// §31.8.2: `from f, nonnull` is a pointer producer that never returns NULL.
// It presents the resource itself, not `Option` of it.
use c_import("void *malloc(unsigned long n);
void free(void *p);
typedef struct { int n; } box;
static inline box *box_new(int n) { box *b = malloc(sizeof(box)); b->n = n; return b; }
static inline int box_n(box *b) { return b->n; }
static inline void box_free(box *b) { free(b); }
")

c contract boxes:
    resource Crate wraps *mut box
        from box_new, nonnull
        drop box_free
    fn box_n
        lend

fn main:
    let b = Crate.new(7)
    print(f"{b.n()}")
    print("ok")
