//! expect-check-stdout: ok

// D51 stage 3 (§16.2b.5): a facade covers a declaration's surface, so the
// call needs no `unsafe`: db_count is described (lend, the default), db_open
// is Database's producer (its out parameter is covered) and db_close its
// drop. The C prototypes have no bodies, so this test only checks (phase lane).
// Twin: err_c_facade_absent_call_stays_raw.

use c_import("typedef struct db db;
int db_open(const char* path, db** out);
void db_close(db* d);
int db_count(db* d);
")

c facade dbl:
    resource Database wraps *mut db
        from db_open(out param 1)
        drop db_close
    fn db_count
        lend

fn main:
    let n = db_count(null)
    db_close(null)
    print(f"{n}")
