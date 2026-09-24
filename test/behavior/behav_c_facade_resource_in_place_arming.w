//! expect-stdout: preinit tag=42 ends=0
//! expect-stdout: failed status=-1 ends=1
//! expect-stdout: destroys 3 ends=2
//! expect-stdout: unread status=-1 live=true ends=3
//! expect-stdout: ok

// D51 ruling §13.1–13.2: Drop arming for an in-place resource. Storage is
// the `preinit` operation's result when the facade names one (the tag it
// sets survives into the live resource). With `ok` the constructor is the
// Result projection (stage 5, Eric 2026-09-23 on #1426): `Stream.z_init`
// returns `Result[Stream, StreamError]`, and a failed init is
// `Err(StreamError.Failed(status))` — no `Stream` exists over storage C did
// not initialize, so neither Drop nor a `destroys` method can run the
// destroyer on it (spec §16.2b.3: "Drop is armed only when initialization
// establishes production"). A `destroys` operation on a live resource
// disarms Drop, so the destroyer runs exactly once. Without `ok` the status
// is uninterpreted: `(status, R)` hands it back unread and the resource is
// live (§16.2b.4). `ends` counts every destroyer call through a counter the
// initializer is handed. `Stream` is `movable` (no operation keeps its
// address — the facade's claim, D54) and so renders over a by-value field;
// `Blind` is pinned. `Stream.z_init` is the presented constructor name (no
// prefix of `z_stream` matches `z_init`, §16.2b.11).

use c_import("void *calloc(unsigned long count, unsigned long size);
void free(void *p);
#define Z_OK 0
typedef struct { int state; int tag; int* ends; } z_stream;
static inline z_stream z_storage(int tag) { z_stream s; s.state = 0; s.tag = tag; s.ends = 0; return s; }
static inline int z_init(z_stream* s, int* ends, int fail) { s->ends = ends; if (fail) return -1; s->state = 7; return Z_OK; }
static inline void z_end(z_stream* s) { (*s->ends)++; s->state = 0; }
static inline int z_end_v2(z_stream* s, int how) { (*s->ends)++; s->state = 0; return how; }
static inline int z_tag(const z_stream* s) { return s->tag; }
")

c facade zl:
    resource Stream wraps z_stream
        movable
        preinit z_storage
        init z_init(self)
        ok Z_OK
        drop z_end
        destroys z_end_v2
    resource Blind wraps z_stream
        init z_init(self)
        drop z_end
    fn z_init
        lend
    fn z_end_v2
        destroys

fn main:
    let ends = unsafe { calloc(1, 4) as *mut c_int }
    let s = Stream.z_init(42, ends, 0).unwrap()
    print(f"preinit tag={unsafe { z_tag(&raw const s.repr) }} ends={unsafe { *ends }}")
    drop(s)
    match Stream.z_init(1, ends, 1):
        Ok(_) => print("bad")
        Err(StreamError.Failed(fst)) => print(f"failed status={fst} ends={unsafe { *ends }}")
    let d = Stream.z_init(2, ends, 0).unwrap()
    let how = d.z_end_v2(3)
    print(f"destroys {how} ends={unsafe { *ends }}")
    let (ust, u) = Blind.z_init(ends, 1)
    let ulive = u.live
    drop(u)
    print(f"unread status={ust} live={ulive} ends={unsafe { *ends }}")
    unsafe { free(ends as *mut c_void) }
    print("ok")
