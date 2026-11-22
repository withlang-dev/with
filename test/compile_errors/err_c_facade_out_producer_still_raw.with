//! expect-check-fail: producer 'db_open' is still a raw call after the facade covers its out parameter
//! expect-check-fail: = help: add 'fn db_open' with a clause for each pointer parameter ('text param N', 'buffer param P len param L', 'param N fixed null')

// D51 stage 5, spec §16.2b.4/§16.2b.5: the constructor of an out-parameter
// producer exposes every parameter but the slot safely, so a raw pointer
// parameter the facade does not describe (here `int *flags`) makes the
// producer a shape the facade must describe with an fn item — never a
// constructor that hands a raw pointer parameter to safe code.

use c_import("typedef struct db db;
int db_open(int* flags, db** out);
void db_close(db* d);
")

c contract dbl:
    resource Database wraps *mut db
        from db_open(out param 1)
        drop db_close

fn main:
    print("ok")
