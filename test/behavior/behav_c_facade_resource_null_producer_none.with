//! expect-stdout: none closes 0
//! expect-stdout: some closes 1
//! expect-stdout: ok

// D51 §16.2b.8/§16.2b.4: unknown nullability is nullable, never silently
// non-null, so a pointer producer's constructor yields `Option[R]`. A NULL
// return produced nothing: `None`, and no Drop ever runs the destroyer over
// it (libc's fclose(NULL) and closedir(NULL) are undefined). The C side
// counts every destroyer call in a counter the producer is handed.

use c_import("void *malloc(unsigned long size);
void *calloc(unsigned long count, unsigned long size);
/* The counters are this snippet's own static state; a Counter names them and holds nothing (D198, spec 16.2b.5). */
static int counter_n_;
typedef struct { int id; } Counter;
typedef struct db { Counter c; } db;
static inline Counter counter_new(void) { Counter c; c.id = 1; counter_n_ = 0; return c; }
static inline int counter_get(Counter c) { return counter_n_; }
static inline db* db_new(Counter c, int id) { if (id < 0) return 0; db* d = (db*)malloc(sizeof(db)); d->c = c; return d; }
static inline void db_close(db* d) { counter_n_++; }
")

c contract dbl:
    resource Database wraps *mut db
        from db_new
        drop db_close

fn main:
    let c = counter_new()
    match Database.new(c, -1):
        Some(_) => print("bad")
        None => print(f"none closes {counter_get(c)}")
    match Database.new(c, 1):
        Some(d) => drop(d)
        None => print("bad")
    print(f"some closes {counter_get(c)}")
    print("ok")
