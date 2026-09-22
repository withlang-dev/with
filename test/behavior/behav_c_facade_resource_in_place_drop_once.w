//! expect-stdout: scope 7 ends=1
//! expect-stdout: early 7 7 ends=3
//! expect-stdout: moved-in 7 ends=4
//! expect-stdout: moved-out 7 ends=5
//! expect-stdout: vec 7 7 ends=7
//! expect-stdout: ok

// D51 §16.2b.3/§16.2b.4 stage 4b: an in-place resource (a by-value C struct
// with `init`) is rendered as ordinary With — storage `z_stream {}`, the C
// initializer over a pointer to it, Drop passing the address to the facade's
// `drop` — and the destructor runs exactly once on every path: scope exit,
// early return, moved into a function, moved out and returned, held in a
// Vec. Each stream remembers a counter the initializer is handed and `z_end`
// bumps it; the counter is never freed, so it stays readable. The resource
// needs no `unsafe`; the observer does, because c_import translates a
// static inline body that reads through a pointer as an `unsafe fn`.

use c_import("void *calloc(unsigned long count, unsigned long size);
typedef struct { int state; int* ends; } z_stream;
static inline void z_init(z_stream* s, int* ends) { s->state = 7; s->ends = ends; }
static inline void z_end(z_stream* s) { (*s->ends)++; s->state = 0; }
static inline int z_state(const z_stream* s) { return s->state; }
")

c facade zl:
    resource Stream wraps z_stream
        init z_init(self)
        drop z_end
    fn z_init
        lend

fn state(s: &Stream) -> c_int: unsafe { z_state(&raw const s.repr) }

fn scope(ends: *mut c_int) -> c_int:
    let s = Stream.z_init(ends)
    state(s)

fn early(ends: *mut c_int, flag: bool) -> c_int:
    let s = Stream.z_init(ends)
    if flag: return state(s)
    print("late")
    state(s)

fn take(s: Stream) -> c_int: state(s)

fn give(ends: *mut c_int) -> Stream:
    let s = Stream.z_init(ends)
    s

fn main:
    let ends = unsafe { calloc(1, 4) as *mut c_int }
    let a = scope(ends)
    print(f"scope {a} ends={unsafe { *ends }}")
    let e1 = early(ends, true)
    let e2 = early(ends, false)
    print(f"early {e1} {e2} ends={unsafe { *ends }}")
    let m = take(Stream.z_init(ends))
    print(f"moved-in {m} ends={unsafe { *ends }}")
    let g = give(ends)
    let gs = state(g)
    drop(g)
    print(f"moved-out {gs} ends={unsafe { *ends }}")
    var v: Vec[Stream] = Vec.new()
    v.push(Stream.z_init(ends))
    v.push(Stream.z_init(ends))
    let s0 = state(v[0])
    let s1 = state(v[1])
    drop(v)
    print(f"vec {s0} {s1} ends={unsafe { *ends }}")
    print("ok")
