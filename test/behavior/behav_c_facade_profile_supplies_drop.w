//! expect-stdout: id 7 unrefs 0
//! expect-stdout: dropped unrefs 1
//! expect-stdout: ok

// D51 stage 11 (ruling §7, §59; spec §16.2b.12): an adopted convention
// profile supplies a resource's production and destruction. The facade
// states only the resource; `gobject.v1` (test/lib/gobject/v1.w) matches
// `obj_new` for `from *_new` (`counter_new` matches the name but not the
// shape: it does not return the representation) and `obj_unref` for
// `drop *_unref`, and its `fn *_get* lend` describes `obj_get_id`, so the
// value is constructed safely, read through `get_id`, and unreffed exactly
// once when its scope ends.

use c_import("void *malloc(unsigned long size);
void *calloc(unsigned long count, unsigned long size);
void free(void *p);
typedef struct { int *n; } Counter;
typedef struct obj { Counter c; int id; } obj;
static inline Counter counter_new(void) { Counter c; c.n = (int *)calloc(1, sizeof(int)); return c; }
static inline int counter_read(Counter c) { return *c.n; }
static inline void counter_free(Counter c) { free(c.n); }
static inline obj *obj_new(Counter c, int id) { obj *o = (obj *)malloc(sizeof(obj)); o->c = c; o->id = id; return o; }
static inline void obj_unref(obj *o) { *o->c.n = *o->c.n + 1; free(o); }
static inline int obj_get_id(obj *o) { return o->id; }
")

c facade objs:
    use convention gobject.v1
    resource Object wraps *mut obj

fn main:
    let c = counter_new()
    if true:
        let o = Object.new(c, 7).unwrap()
        print(f"id {o.get_id()} unrefs {counter_read(c)}")
    print(f"dropped unrefs {counter_read(c)}")
    counter_free(c)
    print("ok")
