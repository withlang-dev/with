//! expect-stdout: closed 7
//! expect-stdout: counts 1 1

// §31.8.6: `destroys g` where `g` is a function-pointer global: an explicit
// consuming operation that calls through the pointer read at the call. Its
// result is the function's. The value it consumed is not dropped again;
// one that is dropped runs `drop`.
use c_import("typedef struct engine { int n; } engine;
typedef int (*engine_close_fn)(engine *e);
static engine lib_engine;
static int lib_closed = 0;
static int lib_dropped = 0;
static inline int lib_close(engine *e) { lib_closed = lib_closed + 1; return 7; }
static inline void engine_free(engine *e) { lib_dropped = lib_dropped + 1; }
static engine_close_fn engine_close = lib_close;
static inline engine *engine_new(void) { return &lib_engine; }
static inline int lib_closed_count(void) { return lib_closed; }
static inline int lib_dropped_count(void) { return lib_dropped; }
")

c contract engine:
    resource Engine wraps *mut engine
        from engine_new
        drop engine_free
        destroys engine_close

fn dropped():
    let Some(e) = Engine.new() else:
        return

fn main:
    let Some(e) = Engine.new() else:
        return
    print(f"closed {e.close()}")
    dropped()
    print(f"counts {lib_closed_count()} {lib_dropped_count()}")
