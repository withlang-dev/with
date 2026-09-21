//! expect-stdout: ok

// D51 §16.2b stage 1: a `c facade` block parses — every item and clause
// form from the specification — and the program still compiles and runs.
// The facts are not collected yet (stage 2); nothing here is enforced.

c facade sqlite:
    resource Database wraps *mut u8
        from sqlite3_open(out param 1)
        drop sqlite3_close
        destroys sqlite3_close_v2
        ok SQLITE_OK
        thread creator
    resource Statement wraps *mut u8
        from sqlite3_prepare_v2(out param 3)
        drop sqlite3_finalize
        borrows param 0
    resource InflateStream wraps u8
        preinit inflate_zero
        init inflateInit(self)
        drop inflateEnd
        independent
    resource SqliteString wraps *mut i8
        from sqlite3_mprintf
        drop sqlite3_free
    fn sqlite3_db_handle
        returns borrow Database from param 0
    fn sqlite3_errstr
        returns static str
    fn sqlite3_create_function
        lend
        consumes param 4 destroyed_by param 8
        retains param 1 by param 0
        callback consumes param 4
        callback_thread any
    fn sqlite3_prepare_v2
        of Database
        rename prepare
        preserves param 0
        preserves domain environ
    fn sqlite3_free
        destroys
    domain errno thread
    domain environ process
    use convention gobject.v1

fn main:
    print("ok")
