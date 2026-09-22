//! expect-stdout: scope 1
//! expect-stdout: early 1 1
//! expect-stdout: moved-in 1
//! expect-stdout: moved-out 1
//! expect-stdout: vec 1 1
//! expect-stdout: texture 1
//! expect-stdout: ok

// D51 §16.2b.3 stage 4a: a facade's pointer resource and by-value resource
// are rendered as ordinary With with a Drop that runs the facade's `drop`
// exactly once on every path — scope exit, early return, moved into a
// function, moved out and returned, held in a Vec. Each C object counts
// its own destructions (`closed`), read back through its raw pointer after
// the resource is gone; the by-value token counts through a slot it names.
// The objects are never freed, so the count stays readable. The resources
// need no `unsafe`; only the observer does, because c_import translates a
// static inline body that reads through a pointer as an `unsafe fn`, and a
// facade lifts imported externs, not raw With bodies.

use c_import("void *malloc(unsigned long size);
void *calloc(unsigned long count, unsigned long size);
typedef struct db { int id; int closed; } db;
typedef struct { int* closed; } Tok;
static inline db* db_new(int id) { db* d = (db*)malloc(sizeof(db)); d->id = id; d->closed = 0; return d; }
static inline void db_close(db* d) { d->closed++; }
static inline int db_closed(db* d) { return d->closed; }
static inline Tok tok_load(const char* path) { Tok t; t.closed = (int*)calloc(1, sizeof(int)); return t; }
static inline void tok_unload(Tok t) { (*t.closed)++; }
static inline int tok_unloads(Tok t) { return *t.closed; }
")

c facade dbl:
    resource Database wraps *mut db
        from db_new
        drop db_close
    resource Texture wraps Tok
        from tok_load
        drop tok_unload

fn scope() -> *mut db:
    let d = Database.db_new(1)
    d.repr

fn early(flag: bool) -> *mut db:
    let d = Database.db_new(2)
    if flag: return d.repr
    print("late")
    d.repr

fn take(d: Database) -> *mut db: d.repr

fn give() -> Database:
    let d = Database.db_new(3)
    d

fn main:
    let s = scope()
    let e1 = early(true)
    let e2 = early(false)
    let m = take(Database.db_new(4))
    let g = give()
    let gp = g.repr
    drop(g)
    var v: Vec[Database] = Vec.new()
    v.push(Database.db_new(5))
    v.push(Database.db_new(6))
    let p5 = v[0].repr
    let p6 = v[1].repr
    drop(v)
    let t = Texture.tok_load("x")
    let tok = t.repr
    drop(t)
    // The observer reads each C object through its raw pointer: raw C.
    unsafe:
        print(f"scope {db_closed(s)}")
        print(f"early {db_closed(e1)} {db_closed(e2)}")
        print(f"moved-in {db_closed(m)}")
        print(f"moved-out {db_closed(gp)}")
        print(f"vec {db_closed(p5)} {db_closed(p6)}")
    print(f"texture {tok_unloads(tok)}")
    print("ok")
