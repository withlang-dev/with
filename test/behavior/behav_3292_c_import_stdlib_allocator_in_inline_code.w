//! expect-stdout: 3
// #3292: a header's inline code that reaches malloc and free through
// <stdlib.h> calls libc's, as written. The system header's declarations are
// filtered from the translation, so these calls were the ones rewritten to
// the runtime's allocator.
use c_import("#include <stdlib.h>
typedef struct db { int n; } db;
static inline db *db_open(int n) { db *d = (db *)malloc(sizeof(db)); d->n = n; return d; }
static inline int db_count(db *d) { return d->n; }
static inline void db_close(db *d) { free(d); }
")

fn main:
    unsafe:
        let d = db_open(3)
        print(db_count(d))
        db_close(d)
