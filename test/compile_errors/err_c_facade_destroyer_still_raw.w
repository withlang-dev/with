//! expect-check-fail: 'db_close_ctx' is still a raw call after the facade covers the representation

// D51 §16.2b.5 stage 4a: a rendered destroyer calls the C operation as a
// safe call because the facade covers the representation parameter. A
// destroyer with a further raw pointer parameter the facade does not
// describe is still raw; the facade must describe it (an fn item) rather
// than the compiler wrapping the call in `unsafe` on the user's behalf.

use c_import("typedef struct db db;
db* db_new(int flags);
void db_close(db* d);
int db_close_ctx(db* d, void* ctx);
")

c facade dbl:
    resource Database wraps *mut db
        from db_new
        drop db_close
        destroys db_close_ctx

fn main:
    print("ok")
