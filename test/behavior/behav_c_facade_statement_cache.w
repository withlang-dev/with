//! expect-stdout: steps: 110 111 110 112 111
//! expect-stdout: prepared: 3
//! expect-stdout: cache dropped: f10 f11 f12
//! expect-stdout: closed after: f10 f11 f12 c1:0
//! expect-stdout: app: 120
//! expect-stdout: app dropped: f20 c1:0
//! expect-stdout: ok

// D51 stage 6 (ruling §30; spec §16.2b.6): `type App { db: Database, stmt:
// Statement }` is a self-referential layout, and the compatible pattern is a
// statement cache owned by the connection's scope: it borrows the
// connection, owns the statements it prepared, and hands each back on a
// repeated request instead of preparing it again. It compiles and runs with
// no `unsafe`, and every statement is finalized before the connection
// closes. The C side logs each finalize (fNN) and each close with the
// statements still open (cD:open). The fix-it the §30 error offers for
// `App`, holding the connection by borrow, compiles and runs too.

use c_import("c_facade_children.h")

c facade dbf:
    resource Database wraps *mut db
        from db_new
        drop db_close
    resource Statement wraps *mut st
        from st_new
        drop st_finalize
    fn st_step
        lend

type StatementCache = ephemeral {
    db: &Database,
    ids: Vec[i32],
    stmts: Vec[Statement],
}

fn StatementCache.over(db: &Database) -> StatementCache: StatementCache { db: db, ids: Vec.new(), stmts: Vec.new() }

impl StatementCache:
    // Prepared once per id; a repeat is served from the cache. The explicit
    // reborrow `&*self.db` works around #1492 (a `&P` field read in a `mut fn`
    // is moved and blanked when `P: Drop`); drop it when #1492 is fixed.
    mut fn step(id: i32) -> i32:
        for i in 0..self.ids.len() as i32:
            if self.ids[i] == id:
                return self.stmts[i].st_step()
        self.ids.push(id)
        self.stmts.push(Statement.st_new(&*self.db, id).unwrap())
        self.stmts[self.stmts.len() as i32 - 1].st_step()

    fn prepared(): self.stmts.len()

type App = ephemeral { db: &Database, stmt: Statement }

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
        let db = Database.db_new(l, 1).unwrap()
        if true:
            var cache = StatementCache.over(db)
            let a = cache.step(10)
            let b = cache.step(11)
            let c = cache.step(10)
            let d = cache.step(12)
            let e = cache.step(11)
            print(f"steps: {a} {b} {c} {d} {e}")
            print(f"prepared: {cache.prepared()}")
        print(f"cache dropped: {witness(l)}")
    print(f"closed after: {witness(l)}")
    log_reset(l)
    if true:
        let db = Database.db_new(l, 1).unwrap()
        let app = App { db: db, stmt: Statement.st_new(db, 20).unwrap() }
        print(f"app: {app.stmt.st_step()}")
    print(f"app dropped: {witness(l)}")
    log_free(l)
    print("ok")
