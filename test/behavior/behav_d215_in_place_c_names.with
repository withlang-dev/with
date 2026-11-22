//! expect-stdout: 0
//! expect-stdout: 11
//! expect-stdout: 12
//! expect-stdout: ended

// D215: an in-place resource's C names are its modeled operations too.
// The producer takes the modeled argument list (the storage slot is what
// the contract removes), an operation's name is the operation, and the
// drop's name consumes.
use c_import("typedef struct iter_s { int n; int base; } iter_s;
static inline int it_init(iter_s* s, int base) { s->n = 0; s->base = base; return 0; }
static inline int it_next(iter_s* s) { s->n += 1; return s->base + s->n; }
static inline void it_end(iter_s* s) { s->n = -1; }
")

c contract its:
    resource Iter wraps iter_s
        init it_init(self)
        drop it_end
    fn it_next
        of Iter
        lend

fn main:
    var (status, s) = it_init(10)
    print(status)
    print(it_next(s))
    print(s.it_next())
    it_end(s)
    print("ended")
