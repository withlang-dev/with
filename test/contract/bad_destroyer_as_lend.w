//! expect-contract: contract: fn 'db_close' (test/contract/bad_destroyer_as_lend.w:14): `lend` at test/contract/bad_destroyer_as_lend.w:15 presents a destroyer of Database as a borrow
//! expect-contract: resolve: remove `lend`
//! expect-contract-not: advisory

// D51 stage 10 (ruling §63): a destroying operation still presented as a
// borrow — `db_close` is the resource's `drop`, and its fn item says `lend`.

use c_import("typedef struct db db;\ndb *db_new(void);\nvoid db_close(db *d);\n")

c facade dbl:
    resource Database wraps *mut db
        from db_new
        drop db_close
    fn db_close
        lend

fn main:
    print("ok")
