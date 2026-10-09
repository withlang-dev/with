//! expect-stdout: id 1 through 1 seen 2
//! expect-stdout: dropped 2

// #2049: a module global's runtime initializer is a synthesized body with
// its own locals. Codegen emitted it with the by-address local map of the
// function generated before it (a facade's borrowed-view method here), so
// the initializer's local 1 was judged "passed by address": `analyze
// audit:all` reported "operand read of an indirect local ...
// __with_init_const_seen subject 1: fact=true llvm-pointer=false", and a
// pointer-typed local in that slot would have been read through an address
// it does not hold. deep-debug-tool-tests audits this program.

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

type Seen { ids: List[i64] }

impl Drop for Seen:
    move fn drop():
        print(f"dropped {self.ids.len()}")

var seen = Seen { ids: List.new() }

fn main:
    let l = log_new()
    if true:
        let db = Database.new(l, 1).unwrap()
        let s = Statement.new(db, 10).unwrap()
        let handle = s.db().unwrap()
        seen.ids.push(db.id() as i64)
        seen.ids.push(handle.id() as i64)
        print(f"id {db.id()} through {handle.id()} seen {seen.ids.len()}")
    log_free(l)
