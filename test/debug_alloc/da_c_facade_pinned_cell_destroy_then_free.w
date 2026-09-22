//! expect-debug-alloc: leak count=0
// Spec §16.2b.3, D54: a pinned in-place resource's cell outlives the C
// state — Drop runs the facade's `drop` first (`z_end` reads and clears
// the state through the address `z_init` kept) and the Box field frees
// the cell after. Every path that moves the value (rebinding, a Vec, a
// function argument, a return) frees its one cell exactly once, and a
// failed init (Drop unarmed) still frees its cell: no leak, no double
// free, no read of a freed cell under the debug allocator.
use c_import("#define Z_OK 0
typedef struct z_stream_s { int state; struct z_stream_s* strm; } z_stream;
static inline int z_init(z_stream* s, int fail) { s->strm = s; if (fail) return -1; s->state = 7; return Z_OK; }
static inline int z_check(const z_stream* s) { return s->strm == s ? s->state : -1; }
static inline void z_end(z_stream* s) { if (s->strm == s && s->state == 7) s->state = 0; }
")

c facade zl:
    resource Stream wraps z_stream
        init z_init(self)
        ok Z_OK
        drop z_end

fn check(s: &Stream) -> c_int: unsafe { z_check(s.repr.as_ptr()) }
fn take(s: Stream) -> c_int: check(s)
fn give() -> Stream:
    let (_, s) = Stream.z_init(0)
    s

fn main:
    let (_, a) = Stream.z_init(0)
    let b = move a
    var v: Vec[Stream] = Vec.new()
    v.push(b)
    v.push(give())
    let n = check(v[0]) + check(v[1]) + take(give())
    let (_, failed) = Stream.z_init(1)
    print(f"{n} {failed.live}")
