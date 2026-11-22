//! expect-check-fail: `Statement.new` is a producer that receives a resource, so it is that resource's method (D214)

// D214: a producer has one home. Without `of`, one that receives a resource
// is that resource's method; the constructor spelling is refused with both
// fixes in the help.
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

fn main:
    let d = Database.new(1).unwrap()
    let s = Statement.new(d, 2).unwrap()
