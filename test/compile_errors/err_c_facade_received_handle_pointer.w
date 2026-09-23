//! expect-check-fail: resource 'Statement': producer 'st_swap' receives param 0: *mut *mut db d, which a borrow of 'Database' cannot hand to C: it points at 'Database''s handle, through which C could replace or release it (§16.2b.6)

// D51 stage 6 (ruling §27): a producer that receives a pointer to a
// resource's handle (other than its own out slot) could replace or release
// the handle; a borrow cannot present it.

use c_import("typedef struct db db;
typedef struct st st;
db* db_new(int flags);
void db_close(db* d);
st* st_swap(db** d);
void st_free(st* s);
")

c facade dep:
    resource Database wraps *mut db
        from db_new
        drop db_close
    resource Statement wraps *mut st
        from st_swap
        drop st_free

fn main:
    print("x")
