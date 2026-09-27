//! expect-check-fail: cannot assign a field of 'Database', a type the facade renders

// Spec §16.2b.3: a resource's representation is what its producer made.
// Replacing it would have Drop destroy a pointer the program chose in safe
// code; a write to a field of a facade-rendered type is refused outside
// its rendering.
use c_import("#include <stdlib.h>\ntypedef struct db { int n; } db;\nstatic inline int db_open(int n, db** out) { db *d = (db *)malloc(sizeof(db)); d->n = n; *out = d; return 0; }\nstatic inline void db_close(db* d) { free(d); }\n")

c facade dbl:
    resource Database wraps *mut db
        from db_open(out param 1)
        drop db_close

fn main:
    let (_, opened) = Database.open(1)
    var d = opened.unwrap()
    d.repr = null
