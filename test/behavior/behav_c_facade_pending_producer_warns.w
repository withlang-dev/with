//! expect-stdout: ok

use pre_d_build_runner

// D51 stage 6: every producer has its constructor, so stage 5's "no
// constructor is rendered" warning is gone. A producer that receives a
// resource gets one whose parameter is a borrow `&P` (spec §16.2b.6); under
// `ok`, a dependent resource's producer projects to
// `Result[R, RError]` whose error is `Failed | NothingProduced` (ruling
// §18: the error never owns a child); and `returns borrow` renders
// `Option[Borrowed<R>]` (ruling §26). The check runs warning-free.
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
    let d = Database.new(0).unwrap()
    let s = Statement.new(d, 1)
    let (status, t) = Statement.open(d)
    let row: Result[Row, RowError] = Row.open(d)
    let back: Option[BorrowedDatabase] = s.unwrap().db()
    match Row.open(d):
        Err(RowError.Failed(st)) => print(\"failed\")
        Err(RowError.NothingProduced(st)) => print(\"none\")
        Ok(_) => print(\"ok\")
    print(\"ok\")
")
    let checked = p7_run(case_dir, "pending-warn", "check\0main.w\0")
    p7_assert_success(checked, "with check")
    assert(not checked.stderr.contains("warning"))
    assert(not checked.stderr.contains("no constructor is rendered"))
    print("ok")
