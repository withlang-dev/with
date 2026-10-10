//! expect-stdout: step 1: 2
//! expect-stdout: step 2: 4
//! expect-stdout: step 3: 6
//! expect-stdout: run returned 10
//! expect-stdout: ok

// #1777 (§16.2b.9): a callback's userdata is borrowed for the call and C
// receives its address. The rendered method passes `ud as *const U as
// *mut c_void`; for a scalar `U` the cast read the value and handed C that
// number as the address, and the callback's `&U` faulted — in safe code.

use c_import("#include <stdlib.h>
typedef struct eng { int base; } eng;
static inline eng *eng_new(int base) { eng *e = (eng *)malloc(sizeof(eng)); e->base = base; return e; }
static inline void eng_free(eng *e) { free(e); }
static inline int eng_run(eng *e, void (*cb)(int n, void *ud), void *ud) {
    for (int i = 1; i <= 3; i++) cb(i, ud);
    return e->base;
}
")

c facade engines:
    resource Engine wraps *mut eng
        from eng_new
        drop eng_free
    fn eng_run
        callback param cb userdata param ud

fn step(n: c_int, scale: &i32):
    print(f"step {n}: {n * scale}")

fn main:
    let e = Engine.new(10).unwrap()
    let scale: i32 = 2
    print(f"run returned {e.run(step, scale)}")
    print("ok")
