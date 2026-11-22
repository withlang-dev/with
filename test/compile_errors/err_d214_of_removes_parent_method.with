//! expect-check-fail: unknown method 'st_new'

// D214: with `of Statement` the producer is a constructor of the produced
// type and no method is generated on the parent.
use c_import("typedef struct db { int n; } db;
typedef struct st { db* owner; int k; } st;
static db the_db; static st the_st;
static inline db* db_new(int n) { the_db.n = n; return &the_db; }
static inline void db_close(db* d) { d->n = -1; }
static inline st* st_new(db* d, int k) { the_st.owner = d; the_st.k = k; return &the_st; }
static inline int st_k(st* s) { return s->k; }
static inline void st_finalize(st* s) { s->k = -1; }
")

c contract dbs:
    resource Database wraps *mut db
        from db_new
        drop db_close
    resource Statement wraps *mut st
        from st_new
        drop st_finalize
    fn st_new
        of Statement

fn main:
    let d = Database.new(1).unwrap()
    let ok = Statement.new(d, 2).unwrap()
    let s = d.st_new(2).unwrap()
