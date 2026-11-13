//! expect-stdout: closed 1
//! expect-stdout: ok

// §31.8.2: the resource states `destroys engine_close`; the fn item carries
// the function's other clauses (here a rename) and does not repeat the fact.
use c_import("void *malloc(unsigned long n);
void free(void *p);
long write(int fd, const void *p, unsigned long n);
typedef struct { int n; } engine;
static inline engine *engine_new(void) { engine *e = malloc(sizeof(engine)); e->n = 1; return e; }
static inline void engine_free(engine *e) { free(e); }
static inline void engine_close(engine *e, int flush) { if (flush == 1) write(1, \"closed 1\\n\", 9); free(e); }
")

c contract engines:
    resource Engine wraps *mut engine
        from engine_new, nonnull
        drop engine_free
        destroys engine_close
    fn engine_close
        rename shut

fn main:
    let e = Engine.new()
    e.shut(1)
    print("ok")
