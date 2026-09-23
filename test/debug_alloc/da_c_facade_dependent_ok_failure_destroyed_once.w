//! expect-debug-alloc: leak count=0
// D51 stage 6, ruling §18 on a dependent resource under the debug
// allocator: a `st_prepare` that fails after producing a statement has it
// destroyed by the constructor exactly once (a second finalize would be a
// DOUBLE FREE, none a LEAK), `Failed` carries nothing, `NothingProduced`
// carries nothing, and a `?` chain over produced statements finalizes each
// before the database closes. The C bodies are translated with the program,
// so every malloc/free is in the ledger.
use c_import("../behavior/c_facade_children.h")

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

fn chain(l: Log) -> Result[i32, StatementError]:
    let db = Database.db_new(l, 3).unwrap()
    let a = Statement.st_prepare(db, 30)?
    let b = Statement.st_prepare(db, -31)?
    Ok(a.st_step() + b.st_step())

fn main:
    let l = log_new()
    if true:
        let db = Database.db_new(l, 1).unwrap()
        for i in 0..3:
            match Statement.st_prepare(db, -10 - i):
                Err(StatementError.Failed(rc)) => assert(rc == 8)
                _ => assert(false)
        match Statement.st_prepare(db, 0):
            Err(StatementError.Failed(rc)) => assert(rc == 7)
            _ => assert(false)
        match Statement.st_prepare(db, 99):
            Err(StatementError.NothingProduced(rc)) => assert(rc == 0)
            _ => assert(false)
        // three finalizes, then the close with nothing open
        assert(log_len(l) == 3)
        assert(log_at(l, 0) == 1010 and log_at(l, 1) == 1011 and log_at(l, 2) == 1012)
    assert(log_len(l) == 4 and log_at(l, 3) == 2010)
    log_reset(l)
    assert(chain(l).is_err())
    assert(log_len(l) == 3 and log_at(l, 0) == 1031 and log_at(l, 1) == 1030 and log_at(l, 2) == 2030)
    log_free(l)
