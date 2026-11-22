//! expect-stdout: 1 0 4 5 11 true
//! expect-stdout: ok

// #1417: the windows.h shapes that failed to type-check once the header
// imported, each in its smallest form.
// - An inline body over a record imported opaque (a bitfield member record,
//   §16.9) is omitted with its reason (err_1417_inline_body_over_opaque_record);
//   one that only passes the pointer on is kept. (It is `same_env`, not
//   `env_same`: an auto-method over the opaque Env trips #1495 on Windows.)
// - An inline body's memset/memcpy lower to with_memset/with_memcpy, which
//   the import now declares (it named an undeclared `with_memset`).
// - A function-like macro's uppercase parameter is a binding (§9.7): it is
//   spelled `p_ENUMTYPE`, in the body too. `fn DEFINE_ENUM_FLAG_OPERATORS(
//   ENUMTYPE: i32)` was a variant pattern.

use c_import("typedef __SIZE_TYPE__ size_t;\nvoid *memset(void *d, int c, size_t n);\nvoid *memcpy(void *d, const void *s, size_t n);\ntypedef struct Env { int version; void *pool; struct { unsigned long_fn : 1; unsigned persistent : 1; } s; } Env;\nstatic inline void env_init(Env *e) { e->version = 3; e->pool = 0; }\nstatic inline int env_size(void) { return (int)sizeof(Env); }\nstatic inline Env *same_env(Env *e) { return e; }\ntypedef struct Plain { int x; int y; } Plain;\nstatic inline void plain_zero(Plain *p) { memset(p, 0, sizeof(Plain)); p->x = 1; }\nstatic inline void plain_copy(Plain *d, const Plain *s) { memcpy(d, s, sizeof(Plain)); }\n#define FLAG_OPS(ENUMTYPE)\n#define PICK_FIRST(A, B) (A)\n")

fn main:
    var p = Plain { x: 7, y: 9 }
    unsafe { plain_zero(&raw mut p) }
    var q = Plain { x: 0, y: 0 }
    let from = Plain { x: 4, y: 5 }
    unsafe { plain_copy(&raw mut q, &raw const from) }
    FLAG_OPS(3)
    let same = unsafe { same_env(null) }
    print(f"{p.x} {p.y} {q.x} {q.y} {PICK_FIRST(11, 12)} {same == null}")
    print("ok")
