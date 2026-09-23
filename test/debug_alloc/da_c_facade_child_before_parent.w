//! expect-debug-alloc: leak count=0
// D51 stage 6 (ruling §29; spec §16.2b.6) under the debug allocator. The C
// bodies are translated with the program, so every database and statement
// malloc and free is in the ledger: a statement never finalized is a LEAK,
// one finalized twice a DOUBLE FREE. A statement depends on its database,
// so it is finalized before the database closes on every path — scope end,
// early return, `?`, a loop's break, a Vec of statements, an Option, a
// helper that borrows the database — and a finalize reads its database
// (which a closed database marks, logging 9999). The order is asserted, so
// a late finalize fails the lane even without scribble.
use c_import("../behavior/c_facade_children.h")

c facade dbf:
    resource Database wraps *mut db
        from db_new
        drop db_close
    resource Statement wraps *mut st
        from db_prepare(out param out)
        from st_new
        drop st_finalize
    fn st_step
        lend

// Every finalize precedes the close that ends its database, and none found
// its database closed.
fn check_order(l: Log, closes: i32):
    var seen = 0
    for i in 0..log_len(l):
        let e = log_at(l, i)
        assert(e != 9999)
        if e >= 2000:
            assert(e % 10 == 0)
            seen = seen + 1
    assert(seen == closes)
    log_reset(l)

fn early(l: Log) -> i32:
    let db = Database.db_new(l, 2).unwrap()
    let s = Statement.st_new(db, 21).unwrap()
    if s.st_step() > 0:
        return 1
    0

fn fails(l: Log) -> Result[i32, str]:
    let db = Database.db_new(l, 3).unwrap()
    let s = Statement.st_new(db, 31).unwrap()
    let (_, none) = Statement.db_prepare(db, -1)
    if none.is_none():
        return Err("nothing")
    Ok(s.st_step())

fn question(l: Log) -> Result[i32, str]:
    let n = fails(l)?
    Ok(n)

fn uses(d: &Database) -> i32:
    let s = Statement.st_new(d, 81).unwrap()
    s.st_step()

fn main:
    let l = log_new()
    if true:
        let db = Database.db_new(l, 1).unwrap()
        let (_, a) = Statement.db_prepare(db, 10)
        let b = Statement.st_new(db, 11).unwrap()
        assert(a.is_some() and b.st_step() == 111)
    check_order(l, 1)
    let _ = early(l)
    check_order(l, 1)
    let _ = question(l)
    check_order(l, 1)
    if true:
        let db = Database.db_new(l, 4).unwrap()
        for i in 1..4:
            let s = Statement.st_new(db, 40 + i).unwrap()
            if i == 3:
                break
            assert(s.st_step() > 0)
    check_order(l, 1)
    if true:
        let db = Database.db_new(l, 5).unwrap()
        var all: Vec[Statement] = Vec.new()
        for i in 1..4:
            all.push(Statement.st_new(db, 50 + i).unwrap())
        assert(all.len() == 3)
    check_order(l, 1)
    if true:
        let db = Database.db_new(l, 6).unwrap()
        let held = Statement.st_new(db, 61)
        assert(held.is_some())
    check_order(l, 1)
    if true:
        let db = Database.db_new(l, 8).unwrap()
        assert(uses(db) == 881)
    check_order(l, 1)
    log_free(l)
