//! expect-stdout: -1 6
//! expect-stdout: true true false
//! expect-stdout: 10 7

// D102 (§16.6, §16.2b.8): c_import places nullability by direction. A
// parameter stays the non-null type, and `nullable param N` widens one
// whose C contract accepts NULL to `Option` of it (no userdata pairing
// needed). A record field and a callback out-parameter are `Option`, in
// both directions: `None` written into the field is C's NULL.
use c_import("typedef int (*op_t)(int);
struct box { op_t f; int (*g)(int); int n; };
static inline int add1(int x) { return x + 1; }
static inline int run(op_t f, int x) { return f ? f(x) : -1; }
static inline void fetch(op_t *out) { *out = add1; }
static inline int call_field(struct box *b, int x) { return b->f ? b->f(x) : 0; }
")

c facade ops:
    fn run
        nullable param 0

fn twice(x: i32): x * 2

fn main:
    print(f"{run(None, 3)} {run(Some(twice), 3)}")
    var b = box.zeroed()
    print(f"{b.f.is_none()} {b.g.is_none()} {unsafe { call_field(&raw mut b, 5) } != 0}")
    b.f = Some(twice)
    var got: Option[op_t] = None
    unsafe { fetch(&raw mut got) }
    print(f"{unsafe { call_field(&raw mut b, 5) }} {got.unwrap()(6)}")
