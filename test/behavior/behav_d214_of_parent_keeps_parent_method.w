//! expect-stdout: 2

// D214: `of` names the home. `of Database` (the resource the producer
// receives) keeps it that resource's method, under its `rename`; this is
// the shape of the SDL scenario's `window.renderer()`.
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
        of Database
        rename statement

fn main:
    let d = Database.new(1).unwrap()
    let s = d.statement(2).unwrap()
    print(2)
