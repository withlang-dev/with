//! expect-check-fail: implicit drop of `keep` uses `&db` after `db` is destroyed (§21.1 Rule 7)

// §21.1 Rule 7 ("implicit drop is a use"): the rule is about a variable whose
// drop runs a destructor that uses the borrow, and an `Option` of a Drop
// value runs that value's destructor when it drops. Declared before its
// origin, `keep` drops after `db`, so its Stmt's destructor would read `db`
// after it is destroyed. Only the bare Drop type was checked before, so the
// `Option` (or a Vec, or a tuple) of it was accepted.

type Db { n: i32, live: bool }
impl Drop for Db:
    move fn drop():
        if self.live: print(f"close db {self.n}")

type Stmt = ephemeral { parent: &Db, n: i32 }
impl Drop for Stmt:
    move fn drop():
        print(f"finalize {self.n} of {self.parent.n}")

fn main:
    var keep: Option[Stmt] = None
    let db = Db { n: 1, live: true }
    keep = Some(Stmt { parent: &db, n: 10 })
    print("end")
