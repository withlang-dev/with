//! expect-check-stdout: ok

// Ruling (Eric, 2026-09-22): `destroys` operations need a `drop`; the
// drop-named form compiles, the drop operation also being a destroyer.

use c_import("typedef struct db db;\ndb* db_new(int id);\nvoid db_close(db* d);\nint db_close_v2(db* d, int how);\n")

c facade dbl:
    resource Database wraps *mut db
        from db_new
        drop db_close
        destroys db_close
        destroys db_close_v2
    fn db_close_v2
        destroys

fn main:
    let d = Database.new(1).unwrap()
    let status = d.close_v2(3)
    print("ok")
