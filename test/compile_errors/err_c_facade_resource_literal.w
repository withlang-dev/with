//! expect-check-fail: 'Database' is a type the facade renders, and only its rendering makes one

// Spec §16.2b.3: a resource is produced by its producers, and its Drop
// destroys what they produced. A literal over a pointer the program chose
// would have Drop run `db_close` on it in safe code; it is refused (the
// representation stays readable as raw access).
use c_import("typedef struct db db;\nint db_open(const char* path, db** out);\nvoid db_close(db* d);\n")

c facade dbl:
    resource Database wraps *mut db
        from db_open(out param 1)
        drop db_close

fn main:
    let d = Database { repr: null, live: true }
    print(f"{d.live}")
