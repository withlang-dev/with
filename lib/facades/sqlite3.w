// The SQLite facade — D51 stage 12, ruling §66: the first complete facade
// written against the ruling, and the executable test of the facade
// language. It is written against the real `sqlite3.h` (the one `c_import`
// resolves on the host) and every sentence of SQLite documentation a clause
// relies on is quoted beside it, from that header.
//
// Where it lives (derived decision, stage 12): the spec puts a facade in the
// importing project's source space or in the C package that ships it
// (§16.2b.1; §18.5: `facade:<package>@<version>`, "the toolchain publishes
// no facade beyond the C standard library's"). `c.sqlite3` is fetched from
// Conan and ships none yet, so this is the project's own facade, under the
// repository's `lib/` — the module root the resolver walks to from every
// fixture (`use facades.sqlite3`) — and not under `lib/std`, which the
// compiler embeds. It moves into the package when the package can carry it.
//
// What the ruling asks for and where it is met (§66):
//   sqlite3 as an owned pointer resource ............ resource Database
//   sqlite3_open out-parameter production ........... from sqlite3_open(out param 1)
//   SQLITE_OK ....................................... ok SQLITE_OK
//   failed-open resource production ................. ok on an out-parameter producer:
//                                                     DatabaseError.FailedWithResource
//   sqlite3_close / sqlite3_close_v2 ................ drop / destroys
//   sqlite3_stmt as a dependent child ............... resource Statement, borrows param 0
//   sqlite3_prepare_v2 / sqlite3_finalize ........... from / drop
//   borrowed text from sqlite3_errmsg ............... returns borrow CStr from param 0
//   nullable borrowed text from sqlite3_column_text . returns borrow CStr from param 0
//   view invalidation across statement mutation ..... step/reset state nothing (invalidate);
//                                                     preserves where the docs guarantee it
//   a callback API with userdata .................... sqlite3_exec
//   consume with destroy callback ................... sqlite3_create_function_v2
//   retained callback lifetime ...................... retains param 5/6/7 by param 0
//   thread capability declarations .................. thread creator (see the note)
//   method presentation from sqlite3_* .............. Database.open, db.exec, stmt.column_text, …
//   an explicit presentation override ............... rename prepare
use c_import("sqlite3.h", link: "sqlite3")

c facade sqlite:
    // A connection is an owned pointer resource (§10, §11). Its producer
    // writes the handle through the second parameter, and the status it
    // returns is read against SQLITE_OK (§16, §17). Production is not
    // success: "Whether or not an error occurs when it is opened, resources
    // associated with the database connection handle should be released by
    // passing it to sqlite3_close() when it is no longer required" — so a
    // failed open that produced a handle is `FailedWithResource`, which owns
    // it as a `FailedDatabase` and closes it (§18). Two destroyers (§23):
    // sqlite3_close is the automatic Drop; sqlite3_close_v2 is the explicit
    // consuming method. Both are consuming; neither is callable as a lend.
    //
    // Threads (§48-§50): a connection is bound to the thread that opened
    // it. SQLite's threading mode is a compile-time and per-connection
    // choice ("The new database connection will use the 'serialized'
    // threading mode" is one of the SQLITE_OPEN_* flags of sqlite3_open_v2,
    // and sqlite3_threadsafe() reports the library's mode only at run
    // time); the header proves neither, and `send`/`share` are never
    // inferred from the representation, so nothing is granted here. A
    // facade that has adopted the serialized mode as trusted evidence may
    // state `thread send share drop_any_thread` for its own connections.
    resource Database wraps *mut sqlite3
        from sqlite3_open(out param 1)
        drop sqlite3_close
        destroys sqlite3_close_v2
        ok SQLITE_OK
        thread creator
    // A prepared statement is produced from a connection and depends on it
    // (§27): it is finalized before the connection closes, on every path,
    // and cannot be stored beside it (§30). `ok SQLITE_OK` projects the
    // producer onto Result[Statement, StatementError]; a dependent value is
    // never carried by an error, so a failed prepare that still produced a
    // handle finalizes it at once (D59).
    resource Statement wraps *mut sqlite3_stmt
        from sqlite3_prepare_v2(out param 3)
        drop sqlite3_finalize
        borrows param 0
        ok SQLITE_OK
        thread creator
    fn sqlite3_close_v2
        destroys
    // The explicit presentation override (§55): the convention would
    // present sqlite3_prepare_v2 as `prepare_v2`; a connection prepares.
    fn sqlite3_prepare_v2
        rename prepare
    // "Memory to hold the error message string is managed internally …
    // the error string might be overwritten or deallocated by subsequent
    // calls to other SQLite interface functions": a view of the
    // connection (§32), invalidated by every operation on it that does not
    // state `preserves` (§38). Valid on the failed state too (§16.2b.4,
    // #1612): "The sqlite3_errmsg() or sqlite3_errmsg16() routines can be
    // used to obtain an English language description of the error
    // following a failure of any of the sqlite3_open() routines" — so a
    // `FailedDatabase` has `errmsg()`, the same view of the failed handle,
    // which nothing else callable on it invalidates.
    fn sqlite3_errmsg
        returns borrow CStr from param 0
        valid on failed
    fn sqlite3_errcode
        lend
    fn sqlite3_changes
        lend
    // sqlite3_exec runs its callback once per result row, during the call
    // (§44): the callback and its userdata are borrowed for the call, and
    // the callback receives the userdata typed (`&U`) where C declares
    // `void *`. The callback is nullable (§43, #1618): "If the callback
    // pointer to sqlite3_exec() is NULL, then no callback is ever invoked
    // and result rows are ignored" — the header
    // states no nullability, so the facade does, and an absent callback
    // takes its userdata with it: `db.exec(sql, None, None, null)` runs
    // DDL and DML with no callback. The fifth parameter, `char **errmsg`,
    // is the raw out slot it is in C; `null` declines it.
    fn sqlite3_exec
        callback param 2 userdata param 3
        nullable param 2
    // "sqlite3_create_function_v2 … xDestroy will be invoked when the
    // function is deleted, either by being overloaded or when the database
    // connection closes": the application data (param 4, `void *pApp`)
    // moves into the connection and C destroys it through xDestroy
    // (param 8) — consume with destroy callback (§24; the ruling's own
    // positional example). The three function pointers are retained by the
    // connection for as long as it lives (§25, §45); a retained callback is
    // a code pointer C receives alone, so only a captureless fn or closure
    // is accepted, and the function reaches its application data through
    // sqlite3_user_data. xDestroy is the compiler's: it is withheld from
    // the method.
    fn sqlite3_create_function_v2
        consumes param 4 destroyed_by param 8
        retains param 5 by param 0
        retains param 6 by param 0
        retains param 7 by param 0
    // Statement operations. The convention shortens by the library prefix
    // the representation's name carries (`sqlite3_` of `sqlite3_stmt`,
    // #1610): `sqlite3_step` is `stmt.step()`, `sqlite3_column_text` is
    // `stmt.column_text(i)`. sqlite3_step and sqlite3_reset state no
    // preservation: "The pointers returned are valid until a type
    // conversion occurs as described above, or until sqlite3_step() or
    // sqlite3_reset() or sqlite3_finalize() is called" — every column view
    // dies at either (§38; finalize is the Drop, so a view cannot outlive
    // it). A column accessor of another type may convert in place, so
    // sqlite3_column_int states nothing either.
    fn sqlite3_step
        lend
    fn sqlite3_reset
        lend
    fn sqlite3_bind_int
        lend
    fn sqlite3_column_int
        lend
    // Reads that touch no value: the column count and a column's declared
    // type perform no conversion ("The value returned by
    // sqlite3_column_type() is only meaningful if no automatic type
    // conversions have occurred" — it reports one, it makes none).
    fn sqlite3_column_count
        lend
        preserves param 0
    fn sqlite3_column_type
        lend
        preserves param 0
    // "The safest policy is to invoke these routines in one of the
    // following ways: sqlite3_column_text() followed by
    // sqlite3_column_bytes() …" — after the text view is taken, the byte
    // count converts nothing, so the view survives it.
    fn sqlite3_column_bytes
        lend
        preserves param 0
    // A NULL column is a NULL pointer: Option[CStr], None for SQL NULL
    // (§41, §43). The bytes are `const unsigned char *` in C — the same
    // NUL-terminated bytes, and `CStr` makes no claim about them.
    fn sqlite3_column_text
        returns borrow CStr from param 0
    // "The returned string pointer is valid until either the prepared
    // statement is destroyed by sqlite3_finalize() or until the statement
    // is automatically reprepared by the first call to sqlite3_step()":
    // a view of the statement, and step invalidates it.
    fn sqlite3_column_name
        returns borrow CStr from param 0
    // Static text: the library's version string (§40).
    fn sqlite3_libversion
        returns static CStr
