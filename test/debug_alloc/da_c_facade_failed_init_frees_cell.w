//! expect-debug-alloc: leak count=0
// D51 stage 5 (Eric, 2026-09-23, on #1426), spec §16.2b.3/D54: a pinned
// in-place resource's representation lives in a Box cell from construction.
// Under `ok`, a failed init is `Err(StreamError.Failed(status))`: nothing was
// produced, so the destroyer never runs, and the cell is freed as ordinary
// With storage — the one path on which the cell is freed with no destruction
// call. Witnesses: the destroyer count stays 0 across failed inits (asserted
// inline), and the ledger shows every cell freed (leak count=0); a live
// stream's cell is freed after its destroyer ran once.
use c_import("void *calloc(unsigned long count, unsigned long size);
void free(void *p);
#define Z_OK 0
typedef struct { int* n; } Counter;
static inline Counter counter_new(void) { Counter c; c.n = (int*)calloc(1, sizeof(int)); return c; }
static inline int counter_get(Counter c) { return *c.n; }
static inline void counter_free(Counter c) { free(c.n); }
typedef struct { int state; Counter ends; } z_stream;
static inline int z_init(z_stream* s, Counter ends, int fail) { s->ends = ends; if (fail) { return -3; } s->state = 7; return Z_OK; }
static inline void z_end(z_stream* s) { *s->ends.n = *s->ends.n + 1; s->state = 0; }
")

c facade zl:
    resource Stream wraps z_stream
        init z_init(self)
        ok Z_OK
        drop z_end

fn main:
    let ends = counter_new()
    for _ in 0..3:
        match Stream.z_init(ends, 1):
            Err(StreamError.Failed(status)) => assert(status == -3)
            Ok(_) => assert(false)
    assert(counter_get(ends) == 0)
    let live = Stream.z_init(ends, 0).unwrap()
    drop(live)
    assert(counter_get(ends) == 1)
    counter_free(ends)
    print("ok")
