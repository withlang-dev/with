//! expect-check-fail: implicit drop of `s` uses `&db` after `db` is moved (§21.1 Rule 7)

// §21.1 Rule 7: moving the origin of a live Drop view is reported at the move
// (`let moved = db`), where the program went wrong, and says the origin was
// moved rather than destroyed.

type Db { n: i32, live: bool }
impl Drop for Db:
    move fn drop():
        if self.live: print(f"close db {self.n}")

type Stmt = ephemeral { parent: &Db, n: i32 }
impl Drop for Stmt:
    move fn drop():
        print(f"finalize {self.n} of {self.parent.n}")

fn main:
    let db = Db { n: 1, live: true }
    let s = Stmt { parent: &db, n: 10 }
    let moved = db
    print(f"{s.n} {moved.n}")
