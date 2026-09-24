//! expect-stdout: scope: f11 f10 c1:0
//! expect-stdout: early return: f21 c2:0
//! expect-stdout: question mark: f31 c3:0
//! expect-stdout: loop: f41 f42 f43 c4:0
//! expect-stdout: vec: f51 f52 f53 c5:0
//! expect-stdout: option: f61 c6:0
//! expect-stdout: match: f71 c7:0
//! expect-stdout: helper: f81 c8:0
//! expect-stdout: returned from helper: 992 f92 c9:0
//! expect-stdout: steps: 110 111
//! expect-stdout: ok

// D51 stage 6 (ruling §27, §29; spec §16.2b.6): a statement produced from a
// database depends on it — unknown independence means dependency — so it is
// destroyed before the database on every path: at scope end, on an early
// return, on `?`, per loop iteration, inside a Vec, inside an Option, in a
// match arm, in a helper that borrows the database, and when a helper
// returns a statement derived from its borrowed database. The C side logs
// each finalize (fNN) and each close with the statements still open at
// that moment (cD:open), and a finalize reads its database, so a statement
// finalized after its database closed would read freed memory.

use c_import("c_facade_children.h")

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
    fn db_id
        lend

fn witness(l: Log) -> str:
    var out = ""
    for i in 0..log_len(l):
        let e = log_at(l, i)
        let word = if e >= 2000: f"c{(e - 2000) / 10}:{(e - 2000) % 10}" else: f"f{e - 1000}"
        out = out ++ (if out.len() > 0: " " else: "") ++ word
    out

fn early(l: Log, stop: bool) -> i32:
    let db = Database.new(l, 2).unwrap()
    let s = Statement.new(db, 21).unwrap()
    if stop:
        return s.step()
    0

fn fails(l: Log) -> Result[i32, str]:
    let db = Database.new(l, 3).unwrap()
    let s = Statement.new(db, 31).unwrap()
    let (status, none) = Statement.prepare(db, -1)
    if none.is_none():
        return Err(f"status {status}")
    Ok(s.step())

fn question(l: Log) -> Result[i32, str]:
    let n = fails(l)?
    Ok(n)

fn uses(d: &Database) -> i32:
    let s = Statement.new(d, 81).unwrap()
    s.step()

fn prepared(d: &Database, id: i32) -> Statement:
    let (_, s) = Statement.prepare(d, id)
    s.unwrap()

fn main:
    let l = log_new()
    if true:
        let db = Database.new(l, 1).unwrap()
        let (_, a) = Statement.prepare(db, 10)
        let b = Statement.new(db, 11).unwrap()
        let _ = a.is_some()
        let _ = b.step()
    print(f"scope: {witness(l)}")
    log_reset(l)
    let _ = early(l, true)
    print(f"early return: {witness(l)}")
    log_reset(l)
    let _ = question(l)
    print(f"question mark: {witness(l)}")
    log_reset(l)
    if true:
        let db = Database.new(l, 4).unwrap()
        for i in 1..4:
            let s = Statement.new(db, 40 + i).unwrap()
            if i == 3:
                break
            let _ = s.step()
    print(f"loop: {witness(l)}")
    log_reset(l)
    if true:
        let db = Database.new(l, 5).unwrap()
        var all: Vec[Statement] = Vec.new()
        for i in 1..4:
            all.push(Statement.new(db, 50 + i).unwrap())
        let _ = all.len()
    print(f"vec: {witness(l)}")
    log_reset(l)
    if true:
        let db = Database.new(l, 6).unwrap()
        let held = Statement.new(db, 61)
        let _ = held.is_some()
    print(f"option: {witness(l)}")
    log_reset(l)
    if true:
        let db = Database.new(l, 7).unwrap()
        match Statement.prepare(db, 71):
            (0, Some(s)) =>
                let _ = s.step()
            _ => ()
    print(f"match: {witness(l)}")
    log_reset(l)
    if true:
        let db = Database.new(l, 8).unwrap()
        let _ = uses(db)
    print(f"helper: {witness(l)}")
    log_reset(l)
    var step = 0
    if true:
        let db = Database.new(l, 9).unwrap()
        let s = prepared(db, 92)
        step = s.step()
    print(f"returned from helper: {step} {witness(l)}")
    log_reset(l)
    if true:
        let db = Database.new(l, 1).unwrap()
        let s = Statement.new(db, 10).unwrap()
        let t = Statement.new(db, 11).unwrap()
        print(f"steps: {s.step()} {t.step()}")
    log_free(l)
    print("ok")
