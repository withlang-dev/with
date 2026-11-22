//! expect-stdout: made
//! expect-stdout: first 1 0
//! expect-stdout: made
//! expect-stdout: second 1 1

// §31.8.6: `drop g` where `g` is a function-pointer global. The pointer is
// read at each call, never cached, so a pointer a raw call replaced is the
// one called: `lib_use_other` assigns the global (so it stays raw), and the
// second engine is released by the replacement.
use c_import("typedef struct engine { int n; } engine;
typedef void (*engine_free_fn)(engine *e);
static engine lib_engine;
static int lib_first = 0;
static int lib_second = 0;
static inline void lib_release_first(engine *e) { lib_first = lib_first + 1; }
static inline void lib_release_second(engine *e) { lib_second = lib_second + 1; }
static engine_free_fn engine_release = lib_release_first;
static inline void lib_use_other(void) { engine_release = lib_release_second; }
static inline engine *engine_new(void) { return &lib_engine; }
static inline int lib_first_count(void) { return lib_first; }
static inline int lib_second_count(void) { return lib_second; }
")

c contract engine:
    resource Engine wraps *mut engine
        from engine_new
        drop engine_release

fn make():
    let Some(e) = Engine.new() else:
        return
    print("made")

fn main:
    make()
    print(f"first {lib_first_count()} {lib_second_count()}")
    unsafe { lib_use_other() }
    make()
    print(f"second {lib_first_count()} {lib_second_count()}")
