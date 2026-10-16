//! expect-check-fail: fn 'db_link': nullable param 1: *mut db other; nullability is rendered for a function-pointer parameter (§16.6), for the callback of a 'callback param N userdata param M' pairing

// D51 stage 12b (#1618; ruling §43, spec §16.2b.8): `nullable param N` is
// rendered for the callback of a userdata pairing, whose absence takes its
// userdata with it, and (D121 step 6) for a `const char *`, which becomes
// `Option[&str]`. On a resource parameter it would mean `Option[&R]`,
// which is not modeled; rather than render the clause as nothing, the
// compiler says so. (A raw pointer parameter accepts `null` as C declares
// it and needs no clause.)
use c_import("typedef struct db db;
db* db_new(int n);
void db_close(db* d);
int db_link(db* d, db* other);
")

c facade dbq:
    resource Database wraps *mut db
        from db_new
        drop db_close
    fn db_link
        lend
        nullable param 1

fn main:
    print("unreachable")
