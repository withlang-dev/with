//! expect-check-fail: fn 'db_name': nullable param 1: *const i8 s; nullability is rendered for the callback of a 'callback param N userdata param M' pairing

// D51 stage 12b (#1618; ruling §43, spec §16.2b.8): `nullable param N` is
// rendered for one shape — the callback of a userdata pairing, whose
// absence takes its userdata with it. On a C string parameter it would
// mean `Option[&str]`, which is not modeled; rather than render the clause
// as nothing, the compiler says so. (A raw pointer parameter accepts
// `null` as C declares it and needs no clause.)
use c_import("typedef struct db db;
db* db_new(int n);
void db_close(db* d);
int db_name(db* d, const char* s);
")

c facade dbq:
    resource Database wraps *mut db
        from db_new
        drop db_close
    fn db_name
        lend
        nullable param 1

fn main:
    print("unreachable")
