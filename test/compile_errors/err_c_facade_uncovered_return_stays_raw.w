//! expect-check-fail: raw c_import function call requires unsafe context

// D51 stage 3: a facade describes db_count but says nothing about db_dup,
// whose pointer return therefore stays raw; coverage is per declaration.
// (D64: db_count lends the resource `Db`; a lend on a bare `db *` no
// resource wraps is refused, err_c_facade_lend_unpaired_buffer.)

use c_import("typedef struct db db;
db* db_new(void);
void db_free(db* d);
db* db_dup(db* d);
int db_count(db* d);
")

c facade dbl:
    resource Db wraps *mut db
        from db_new
        drop db_free
    fn db_count
        lend

fn main:
    let d = db_dup(null)
    print("unreachable")
