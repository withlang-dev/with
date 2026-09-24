//! expect-stdout: borrowed: id 1 through 1
//! expect-stdout: nullable: some=true none=true
//! expect-stdout: order: f10 c1:0
//! expect-stdout: ok

// D51 stage 6, ruling §26: `returns borrow Database from param 0` on
// `st_db(st *)` renders `Statement.db() -> Option[BorrowedDatabase]`.
// `BorrowedDatabase` has no Drop (nothing is closed through it — the log
// shows one finalize and one close), cannot outlive the statement, and
// carries the database's lend methods (`db_id`) and none of its destroyers.
// Unknown nullability is nullable: the operation that may return NULL and
// the one that never does both yield an Option. `db_id` states `preserves
// param 0` (stage 7, ruling §38): the borrowed database is read after a
// lend on the database it views, and an undescribed lend's unknown effect
// would invalidate it.

use c_import("c_facade_children.h")

c facade dbf:
    resource Database wraps *mut db
        from db_new
        drop db_close
        destroys db_close_v2
    resource Statement wraps *mut st
        from st_new
        drop st_finalize
    fn db_id
        lend
        preserves param 0
    fn db_close_v2
        destroys
    fn st_db
        returns borrow Database from param 0
    fn st_db_or_null
        returns borrow Database from param 0

fn witness(l: Log) -> str:
    var out = ""
    for i in 0..log_len(l):
        let e = log_at(l, i)
        let word = if e >= 2000: f"c{(e - 2000) / 10}:{(e - 2000) % 10}" else: f"f{e - 1000}"
        out = out ++ (if out.len() > 0: " " else: "") ++ word
    out

fn main:
    let l = log_new()
    if true:
        let db = Database.new(l, 1).unwrap()
        let s = Statement.new(db, 10).unwrap()
        let handle = s.db().unwrap()
        print(f"borrowed: id {db.id()} through {handle.id()}")
        print(f"nullable: some={s.db_or_null(1).is_some()} none={s.db_or_null(0).is_none()}")
    print(f"order: {witness(l)}")
    log_free(l)
    print("ok")
