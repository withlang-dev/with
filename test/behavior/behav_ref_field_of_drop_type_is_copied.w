//! expect-stdout: 111 110
//! expect-stdout: close db 1

// #1492 / §3: a `&Db` field is Copy whatever `Db` implements — reading it
// out of a `mut self` receiver copies the reference, never moves and blanks
// the field (the second `step` read a null parent and crashed).
type Db { n: i32, live: bool }
impl Drop for Db:
    move fn drop():
        if self.live: print(f"close db {self.n}")
type Stmt = ephemeral { parent: &Db, n: i32 }
impl Stmt:
    fn step(): self.parent.n * 100 + self.n
type Cache = ephemeral { db: &Db, stmts: Vec[Stmt] }
impl Cache:
    mut fn step(id: i32) -> i32:
        self.stmts.push(Stmt { parent: self.db, n: id })
        self.stmts[self.stmts.len() as i32 - 1].step()
fn Cache.over(db: &Db) -> Cache: Cache { db: db, stmts: Vec.new() }
fn main:
    let db = Db { n: 1, live: true }
    var cache = Cache.over(db)
    let b = cache.step(11)
    let c = cache.step(10)
    print(f"{b} {c}")
