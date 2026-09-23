//! expect-stdout: ok

use pre_d_build_runner

// D51 stage 6: a producer that receives a resource gets its constructor — the
// received resource is a borrow `&P`, and the product depends on it (spec
// §16.2b.6: unknown independence means dependency) — so stage 5's "no
// constructor" warning for it is gone. One shape still renders none, and says
// so at its resource: under `ok`, an out-parameter producer's failure that
// still produced is owned by `<R>Error.FailedWithResource` (§16.2b.4), and a
// dependent resource's failed state depends on its parents too; an `error`
// declaration cannot carry a dependent value, and that projection is not
// ruled. A `returns borrow` operation is collected and verified but has no
// With type for its borrowed result yet, and says so at the fn item.
fn main:
    let case_dir = p7_prepare_case("c_facade_pending_producer_warns", "pendwarn")
    p7_write(case_dir, "main.w", "use c_import(\"typedef struct db db;
typedef struct st st;
typedef struct rw rw;
#define DB_OK 0
db* db_new(int flags);
int db_open(const char* path, db** out);
void db_close(db* d);
st* st_new(db* d, int n);
int st_open(db* d, st** out);
void st_free(st* s);
int rw_open(db* d, rw** out);
void rw_free(rw* r);
db* st_db(st* s);
\")

c facade dep:
    resource Database wraps *mut db
        from db_new
        from db_open(out param 1)
        drop db_close
        ok DB_OK
    resource Statement wraps *mut st
        from st_new
        from st_open(out param 1)
        drop st_free
    resource Row wraps *mut rw
        from rw_open(out param out)
        drop rw_free
        ok DB_OK
    fn st_db
        returns borrow Database from param 0

fn main:
    let d = Database.db_new(0).unwrap()
    let s = Statement.st_new(d, 1)
    let (status, t) = Statement.st_open(d)
    print(\"ok\")
")
    let checked = p7_run(case_dir, "pending-warn", "check\0main.w\0")
    p7_assert_success(checked, "with check")
    assert(checked.stderr.contains("resource 'Row': no constructor is rendered for producer 'rw_open': under 'ok DB_OK' a failure that still produced a 'Row' is owned by 'RowError.FailedWithResource', and a dependent 'Row' depends on its parents there too"))
    assert(checked.stderr.contains("fn 'st_db': no safe operation is rendered for 'returns borrow Database from param 0' (param 0: *mut st s)"))
    assert(not checked.stderr.contains("producer 'st_new'"))
    assert(not checked.stderr.contains("producer 'st_open'"))
    assert(not checked.stderr.contains("producer 'db_open'"))
    assert(not checked.stderr.contains("producer 'db_new'"))
    print("ok")
