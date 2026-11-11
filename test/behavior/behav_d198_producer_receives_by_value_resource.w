//! expect-stdout: none closes 0
//! expect-stdout: some closes 1
//! expect-stdout: ok

// §16.2b.3: a by-value record a resource wraps is that resource wherever it
// is passed. The producer `db_new(Counter c, int id)` takes a record that
// holds a pointer; with `Counter` modeled as a resource the parameter is a
// borrow of it, the database depends on it, and the described `counter_get`
// is its operation. The record was recognized only where an `of` said so,
// and the producer was refused as "still a raw call".
use c_import("void *malloc(unsigned long size);
void *calloc(unsigned long count, unsigned long size);
void free(void *p);
typedef struct { int* n; } Counter;
typedef struct db { Counter c; } db;
static inline Counter counter_new(void) { Counter c; c.n = (int*)calloc(1, sizeof(int)); return c; }
static inline void counter_free(Counter c) { free(c.n); }
static inline int counter_get(Counter c) { return *c.n; }
static inline db* db_new(Counter c, int id) { if (id < 0) return 0; db* d = (db*)malloc(sizeof(db)); d->c = c; return d; }
static inline void db_close(db* d) { (*d->c.n)++; }
")

c facade dbl:
    resource Tally wraps Counter
        from counter_new
        drop counter_free
    fn counter_get
        of Tally
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
