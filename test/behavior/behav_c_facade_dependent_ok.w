//! expect-stdout: ok: 110 f10 c1:0
//! expect-stdout: failed: Failed(7) c1:0
//! expect-stdout: failed but produced: Failed(8) f20 c2:0
//! expect-stdout: nothing produced: NothingProduced(0) c2:0
//! expect-stdout: question mark: f31 f30 c3:0
//! expect-stdout: ok

// D51 stage 6, ruling §18 ("A facade-specific error type may itself
// temporarily own the failure-state resource where required") on a
// dependent resource: the generated error never owns a child — an error
// escapes scopes, a dependent value cannot — so `ok ST_OK` on a statement
// producer renders `Result[Statement, StatementError]` with
// `StatementError = Failed | NothingProduced`, and a failure that still
// produced is destroyed at once by the facade's `drop` (the finalize is
// logged, exactly once) and reported as `Failed`. `?` moves the error up
// while the statements that were produced finalize before their database.

use c_import("c_facade_children.h")

c facade dbf:
    resource Database wraps *mut db
        from db_new
        drop db_close
    resource Statement wraps *mut st
        from st_prepare(out param out)
        drop st_finalize
        ok ST_OK
    fn st_step
        lend

fn witness(l: Log) -> str:
    var out = ""
    for i in 0..log_len(l):
        let e = log_at(l, i)
        let word = if e >= 2000: f"c{(e - 2000) / 10}:{(e - 2000) % 10}" else: f"f{e - 1000}"
        out = out ++ (if out.len() > 0: " " else: "") ++ word
    out

fn two(l: Log) -> Result[i32, StatementError]:
    let db = Database.db_new(l, 3).unwrap()
    let a = Statement.st_prepare(db, 30)?
    let b = Statement.st_prepare(db, 31)?
    let c = Statement.st_prepare(db, 0)?
    Ok(a.st_step() + b.st_step() + c.st_step())

fn main:
    let l = log_new()
    var step = 0
    var shown = ""
    if true:
        let db = Database.db_new(l, 1).unwrap()
        let s = Statement.st_prepare(db, 10).unwrap()
        step = s.st_step()
    print(f"ok: {step} {witness(l)}")
    log_reset(l)
    if true:
        let db = Database.db_new(l, 1).unwrap()
        match Statement.st_prepare(db, 0):
            Err(e) => shown = f"{e:?}"
            Ok(_) => print("unexpected")
    print(f"failed: {shown} {witness(l)}")
    log_reset(l)
    if true:
        let db = Database.db_new(l, 2).unwrap()
        match Statement.st_prepare(db, -20):
            Err(e) => shown = f"{e:?}"
            Ok(_) => print("unexpected")
    print(f"failed but produced: {shown} {witness(l)}")
    log_reset(l)
    if true:
        let db = Database.db_new(l, 2).unwrap()
        match Statement.st_prepare(db, 99):
            Err(e) => shown = f"{e:?}"
            Ok(_) => print("unexpected")
    print(f"nothing produced: {shown} {witness(l)}")
    log_reset(l)
    let _ = two(l)
    print(f"question mark: {witness(l)}")
    log_free(l)
    print("ok")
