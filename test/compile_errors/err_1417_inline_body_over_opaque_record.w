//! expect-error: c_import symbol 'env_init' was omitted: inline body needs the layout of 'Env', which c_import imports opaque (§16.9)

// #1417: winnt.h's FORCEINLINE TpInitializeCallbackEnviron writes the fields
// of _TP_CALLBACK_ENVIRON_V3, a record holding a bitfield record, which
// c_import imports opaque (§16.9). Its body was emitted anyway and failed to
// type-check ("field access requires a concrete struct or union type; this
// type is opaque", "null requires pointer type context"). It is omitted with
// the reason, and naming it says so.

use c_import("typedef struct Env { int version; void *pool; struct { unsigned long_fn : 1; unsigned persistent : 1; } s; } Env;\nstatic inline void env_init(Env *e) { e->version = 3; e->pool = 0; e->s.long_fn = 1; }\n")

fn main:
    env_init
