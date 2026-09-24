//! expect-stdout: ctor 7
//! expect-stdout: moved 7 raw-across-move 7
//! expect-stdout: vec 7 7
//! expect-stdout: fn 7
//! expect-stdout: ends=4 misplaced=0
//! expect-stdout: ok

// Spec §16.2b.3, D54: an in-place resource is pinned — its representation
// has one address from the creation of the resource value until foreign
// destruction completes, and moving the value does not move it. The
// header's `z_init` keeps the address it is called with (zlib's
// `state->strm`), `z_check` returns the state only while that address is
// still the stream's own, and `z_end` counts a destruction only at the
// kept address and reads the state first — so it runs on a live cell
// (destroy, then free) and exactly once per resource: returned from the
// constructor, moved to a new binding, pushed into a Vec, moved into a
// function. A raw pointer taken from a borrow of the representation stays
// valid across a move of the resource value. `misplaced` counts every
// operation that saw the stream at another address.

use c_import("void *calloc(unsigned long count, unsigned long size);
typedef struct z_stream_s { int state; struct z_stream_s* strm; int* ends; int* misplaced; } z_stream;
static inline int z_init(z_stream* s, int* ends, int* misplaced) { s->state = 7; s->strm = s; s->ends = ends; s->misplaced = misplaced; return 0; }
static inline int z_check(const z_stream* s) { if (s->strm != s) { (*s->misplaced)++; return -1; } return s->state; }
static inline void z_end(z_stream* s) { if (s->strm != s || s->state != 7) { (*s->misplaced)++; return; } s->state = 0; (*s->ends)++; }
")

c facade zl:
    resource Stream wraps z_stream
        init z_init(self)
        drop z_end
    fn z_init
        lend

fn check(s: &Stream) -> c_int: unsafe { z_check(s.repr.as_ptr()) }

fn take(s: Stream) -> c_int: check(s)

fn make(ends: *mut c_int, misplaced: *mut c_int) -> Stream:
    let (_, s) = Stream.init(ends, misplaced)
    s

fn main:
    let ends = unsafe { calloc(1, 4) as *mut c_int }
    let misplaced = unsafe { calloc(1, 4) as *mut c_int }
    let (_, a) = Stream.init(ends, misplaced)
    print(f"ctor {check(a)}")
    let p = a.repr.as_ptr()
    let b = move a
    print(f"moved {check(b)} raw-across-move {unsafe { z_check(p) }}")
    var v: Vec[Stream] = Vec.new()
    v.push(b)
    v.push(make(ends, misplaced))
    print(f"vec {check(v[0])} {check(v[1])}")
    drop(v)
    let f = take(make(ends, misplaced))
    print(f"fn {f}")
    let (_, last) = Stream.init(ends, misplaced)
    drop(last)
    print(f"ends={unsafe { *ends }} misplaced={unsafe { *misplaced }}")
    print("ok")
