//! expect-check-fail: resource 'Iter': 'preinit it_storage' receives param 0: *mut db d; preinit only constructs storage, and a resource an in-place resource depends on is received by its 'init'

// D51 stage 6 (ruling §13.1, §27): preinit constructs storage and produces
// nothing; the parent of an in-place resource is received by its init.

use c_import("typedef struct db db;
typedef struct { int pos; } iter_state;
db* db_new(int flags);
void db_close(db* d);
iter_state it_storage(db* d);
void it_init(iter_state* it, int n);
void it_end(iter_state* it);
")

c facade dep:
    resource Database wraps *mut db
        from db_new
        drop db_close
    resource Iter wraps iter_state
        preinit it_storage
        init it_init(self)
        drop it_end

fn main:
    print("x")
