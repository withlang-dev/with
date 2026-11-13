//! expect-check-fail: fn 'engine_close': a resource names it as a destroyer, and the fn item says 'lend'

// §31.8.2: the resource owns "f destroys N"; an explicit `lend` on the fn
// item of a destroyer is an error.
use c_import("typedef struct eng eng;\neng *engine_new(void);\nvoid engine_free(eng *e);\nvoid engine_close(eng *e, int flush);\n")

c contract engines:
    resource Engine wraps *mut eng
        from engine_new
        drop engine_free
        destroys engine_close
    fn engine_close
        lend

fn main:
    print("unreachable")
