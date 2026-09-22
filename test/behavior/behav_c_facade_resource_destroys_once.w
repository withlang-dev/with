//! expect-stdout: status 42
//! expect-stdout: destroyed 1
//! expect-stdout: still 1
//! expect-stdout: dropped 1
//! expect-stdout: same-fn 1
//! expect-stdout: ok

// D51 §16.2b.3 stage 4a: a `destroys` operation is a `move fn` method that
// consumes the resource; after it the type's Drop must not run the `drop`
// operation again (a destroyer that read `self.repr` and let `self` drop
// destroyed twice — each C object counts its destructions and is the
// witness). A resource may name the same function as `drop` and `destroys`.

use c_import("void *malloc(unsigned long size);
typedef struct db { int id; int closed; } db;
static inline db* db_new(int id) { db* d = (db*)malloc(sizeof(db)); d->id = id; d->closed = 0; return d; }
static inline void db_close(db* d) { d->closed++; }
static inline int db_close_v2(db* d, int how) { d->closed++; return how; }
static inline int db_closed(db* d) { return d->closed; }
")

c facade dbl:
    resource Database wraps *mut db
        from db_new
        drop db_close
        destroys db_close_v2
        destroys db_close
    fn db_close_v2
        destroys

fn destroy_v2() -> *mut db:
    let a = Database.db_new(1).unwrap()
    let p = a.repr
    let status = a.db_close_v2(42)
    print(f"status {status}")
    // The observer reads through the pointer (raw C); the resource
    // operations need no `unsafe`.
    unsafe { print(f"destroyed {db_closed(p)}") }
    p

fn main:
    let p = destroy_v2()
    unsafe { print(f"still {db_closed(p)}") }
    let b = Database.db_new(2).unwrap()
    let pb = b.repr
    drop(b)
    unsafe { print(f"dropped {db_closed(pb)}") }
    let c = Database.db_new(3).unwrap()
    let pc = c.repr
    c.db_close()
    unsafe { print(f"same-fn {db_closed(pc)}") }
    print("ok")
