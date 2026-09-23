//! expect-debug-alloc: leak count=0
// D51 stage 5, spec §16.2b.4: every production form under the debug
// allocator. The C bodies are translated with the program, so the
// representation's malloc and the destroyer's free are in the ledger: a
// produced resource that Drop never destroyed is a LEAK, one destroyed twice
// is a DOUBLE FREE. Direct return (a NULL return produced nothing), out
// parameter (success with a handle, failure with none, failure that still
// produced a handle — its Drop destroys it — success without one, a void
// producer), and in place (the pinned cell freed after its destroyer). Values
// move through a Vec, a function argument and a return.
use c_import("void *malloc(unsigned long size);
void free(void *p);
typedef struct db { int tag; } db;
static inline db* db_alloc(int tag) { db* d = (db*)malloc(sizeof(db)); d->tag = tag; return d; }
static inline db* db_new(int tag) { if (tag < 0) { return 0; } return db_alloc(tag); }
static inline int db_open(int mode, db** out) {
    if (mode == 1) { return -1; }
    if (mode == 3) { return 0; }
    *out = db_alloc(mode);
    if (mode == 2) { return 14; }
    return 0;
}
static inline void db_make(int produce, db** out) { if (produce != 0) { *out = db_alloc(9); } }
static inline void db_close(db* d) { free(d); }
typedef struct { int* buf; } z_stream;
static inline int z_init(z_stream* s, int n) { s->buf = (int*)malloc(sizeof(int) * n); return 0; }
static inline void z_end(z_stream* s) { free(s->buf); s->buf = 0; }
")

c facade forms:
    resource Database wraps *mut db
        from db_new
        from db_open(out param 1)
        from db_make(out param 1)
        drop db_close
    resource Stream wraps z_stream
        init z_init(self)
        drop z_end

fn take(d: Database) -> Database: d

fn opened(mode: c_int) -> Option[Database]:
    let (_, d) = Database.db_open(mode)
    d

fn main:
    var v: Vec[Database] = Vec.new()
    v.push(Database.db_new(1).unwrap())
    let none = Database.db_new(-1)
    for mode in 0..4:
        let (_, d) = Database.db_open(mode)
        match d:
            Some(db) => v.push(take(db))
            None => {}
    let failed_but_produced = opened(2)
    let made = Database.db_make(1)
    let nothing = Database.db_make(0)
    let (_, s) = Stream.z_init(4)
    var cells: Vec[Stream] = Vec.new()
    cells.push(s)
    let (_, t) = Stream.z_init(2)
    let moved = move t
    print(f"{v.len()} {none.is_some()} {failed_but_produced.is_some()} {made.is_some()} {nothing.is_some()} {cells.len()} {moved.live}")
