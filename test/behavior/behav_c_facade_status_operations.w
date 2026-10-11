//! expect-stdout: run: true ran=1
//! expect-stdout: run failed: 7 no such code
//! expect-stdout: run_times: true ran=4
//! expect-stdout: run_times failed: 9 no such code
//! expect-stdout: rows: 3
//! expect-stdout: done again: true
//! expect-stdout: busy: 5 database is busy
//! expect-stdout: question mark: Failed(5, "database is busy")
//! expect-stdout: plain: Failed(3)
//! expect-stdout: ok

// D92 (ruling Amendment 3; spec §16.2b.4, §16.2b.11), the three clauses on
// a counting C API:
//   - `ok CONST` on an operation whose return is its status: the method is
//     `Result[Unit, <Fn>Error]`, so `db.run(0)?` is the call;
//   - `ok C1, C2`: either is success and `Ok` carries the one that matched,
//     so a loop reads rows with `while db.step()? == DB_ROW:`;
//   - `message <fn>` on the resource: each of its operations' errors is
//     `Failed(status, message)`, the text an owned copy read at the failure
//     (the later successful calls below do not change what was printed);
//     a resource stating none keeps `Failed(status)`;
//   - one C function presented twice under distinct renames, each with its
//     own fixed arguments and its own error type.
use c_import("c_facade_status_ops.h")

c facade dbs:
    resource Database wraps *mut db
        from db_new
        drop db_close
        message db_errmsg
    fn db_errmsg
        returns borrow CStr from param 0
    fn db_ran
        lend
    fn db_run
        rename run
        param times fixed 1
        ok DB_OK
    fn db_run
        rename run_times
        ok DB_OK
    fn db_step
        ok DB_ROW, DB_DONE
    resource Plain wraps *mut plain
        from plain_new
        drop plain_free
    fn plain_poke
        ok DB_OK

fn rows(db: &Database) -> Result[i32, StepError]:
    var n: i32 = 0
    while db.step()? == DB_ROW: n += 1
    n

fn main:
    let db = Database.new(3).unwrap()
    print(f"run: {db.run(0).is_ok()} ran={db.ran()}")
    let failed = db.run(7)
    // A later success: the message was copied when the failure happened.
    let later = db.run_times(0, 3)
    match failed:
        Err(RunError.Failed(status, message)) => print(f"run failed: {status} {message}")
        Ok(_) => print("unexpected")
    print(f"run_times: {later.is_ok()} ran={db.ran()}")
    match db.run_times(9, 2):
        Err(RunTimesError.Failed(status, message)) => print(f"run_times failed: {status} {message}")
        Ok(_) => print("unexpected")
    print(f"rows: {rows(db).unwrap()}")
    print(f"done again: {db.step().unwrap() == DB_DONE}")
    let busy = Database.new(-1).unwrap()
    match busy.step():
        Err(StepError.Failed(status, message)) => print(f"busy: {status} {message}")
        Ok(_) => print("unexpected")
    match rows(busy):
        Err(e) => print(f"question mark: {e:?}")
        Ok(_) => print("unexpected")
    let p = Plain.new().unwrap()
    match p.poke(3):
        Err(e) => print(f"plain: {e:?}")
        Ok(_) => print("unexpected")
    print("ok")
