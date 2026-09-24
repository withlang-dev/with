//! expect-check-fail: has 2 'void *' parameter(s); a callback receiving userdata has exactly one

// D51 stage 9 (spec §16.2b.9): the userdata arrives in the callback's one
// `void *` parameter; a callback with two is not paired (which one would
// be typed is capability-granting, never guessed).
use c_import("typedef struct db db;\nvoid *malloc(unsigned long size);\nvoid free(void *p);\nstatic inline db *db_new(void) { return (db *)malloc(8); }\nstatic inline void db_close(db *d) { free(d); }\nstatic inline int db_exec2(db *d, int (*cb)(void *, void *), void *ud) { return cb(ud, ud); }\n")

c facade dbc:
    resource Database wraps *mut db
        from db_new
        drop db_close
    fn db_exec2
        callback param 1 userdata param 2

fn main:
    print("ok")
