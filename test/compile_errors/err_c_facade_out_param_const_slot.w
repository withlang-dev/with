//! expect-check-fail: the out parameter param 1: *const *mut db out is a pointer to const; C cannot store the produced resource through it

// D51 stage 5, ruling §61 "producer return/out parameter matches", spec
// §16.2b.4: the out slot is where C stores the produced resource, so it is a
// pointer to a mutable slot. `db * const *` is a slot C cannot write.

use c_import("typedef struct db db;
int db_open(const char* path, db* const* out);
void db_close(db* d);
")

c facade dbl:
    resource Database wraps *mut db
        from db_open(out param 1)
        drop db_close

fn main:
    print("ok")
