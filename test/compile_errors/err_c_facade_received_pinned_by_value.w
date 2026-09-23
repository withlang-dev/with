//! expect-check-fail: resource 'Summary': producer 'sum_new' receives param 0: z_stream s, which a borrow of 'Stream' cannot hand to C: 'Stream' is pinned in place, and a copy of its representation is not the resource (§16.2b.3) (§16.2b.6)

// D51 stage 6 (ruling §13, D54): a pinned in-place resource is reached by
// the address of its storage; a producer taking the representation by value
// would receive a copy, which a borrow of the resource cannot present.

use c_import("typedef struct { int n; } z_stream;
typedef struct sm sm;
void z_init(z_stream* s);
void z_end(z_stream* s);
sm* sum_new(z_stream s);
void sum_free(sm* m);
")

c facade dep:
    resource Stream wraps z_stream
        init z_init(self)
        drop z_end
    resource Summary wraps *mut sm
        from sum_new
        drop sum_free

fn main:
    print("x")
