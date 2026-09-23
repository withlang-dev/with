//! expect-stdout: direct repr=5 closes=1
//! expect-stdout: out status=0 tag=9 closes=2
//! expect-stdout: in place status=0 tag=11 ends=1
//! expect-stdout: ok

// D51 stage 5 (spec §16.2b.4): each production form binds locals in its
// rendered constructor — the returned representation, the out slot, the
// status, the in-place storage — and With refuses shadowing. A C parameter
// may be named like any of them, so the rendering spells its locals apart
// from the constructor's parameters: a direct-return producer taking `repr`,
// an out-parameter producer whose slot is `slot` and which takes `status`,
// and an in-place initializer taking `repr` and `status` all render, and
// each argument reaches C as the caller wrote it.

use c_import("void *malloc(unsigned long size);
void *calloc(unsigned long count, unsigned long size);
void free(void *p);
typedef struct { int* closes; } Counter;
typedef struct db { Counter c; int tag; } db;
static inline Counter counter_new(void) { Counter c; c.closes = (int*)calloc(1, sizeof(int)); return c; }
static inline int counter_closes(Counter c) { return *c.closes; }
static inline void counter_free(Counter c) { free(c.closes); }
static inline db* db_new(Counter c, int repr) { db* d = (db*)malloc(sizeof(db)); d->c = c; d->tag = repr; return d; }
static inline int db_open(Counter c, int status, db** slot) { db* d = (db*)malloc(sizeof(db)); d->c = c; d->tag = status; *slot = d; return 0; }
static inline int db_tag(db* d) { return d->tag; }
static inline void db_close(db* d) { *d->c.closes = *d->c.closes + 1; free(d); }
typedef struct { int tag; int* ends; } z_stream;
static inline int z_init(z_stream* s, int* ends, int repr, int status) { s->ends = ends; s->tag = repr + status; return 0; }
static inline int z_tag(const z_stream* s) { return s->tag; }
static inline void z_end(z_stream* s) { *s->ends = *s->ends + 1; }
")

c facade names:
    resource Database wraps *mut db
        from db_new
        from db_open(out param slot)
        drop db_close
    resource Stream wraps z_stream
        movable
        init z_init(self)
        drop z_end
    fn z_init
        lend

fn main:
    let c = counter_new()
    let direct = Database.db_new(c, 5).unwrap()
    let t = unsafe { db_tag(direct.repr) }
    drop(direct)
    print(f"direct repr={t} closes={counter_closes(c)}")
    let (st, made) = Database.db_open(c, 9)
    let d = made.unwrap()
    let t2 = unsafe { db_tag(d.repr) }
    drop(d)
    print(f"out status={st} tag={t2} closes={counter_closes(c)}")
    let ends = unsafe { calloc(1, 4) as *mut c_int }
    let (ist, s) = Stream.z_init(ends, 4, 7)
    let t3 = unsafe { z_tag(&raw const s.repr) }
    drop(s)
    print(f"in place status={ist} tag={t3} ends={unsafe { *ends }}")
    counter_free(c)
    unsafe { free(ends as *mut c_void) }
    print("ok")
