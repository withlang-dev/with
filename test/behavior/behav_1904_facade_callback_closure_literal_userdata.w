//! expect-stdout: 2
// #1904 (§16.2b.9, §12.4): a captureless closure literal given directly as
// a receiver callback method's `&U` userdata is auto-borrowed exactly as a
// bound closure is; MIR gets the borrow Sema recorded (D65).
use c_import("c_facade_callbacks.h")

c facade dbc:
    resource Database wraps *mut db
        from db_new
        drop db_close
    fn db_exec
        callback param 1 userdata param 2

fn invoke(f: &fn(c_int) -> c_int, n: c_int) -> c_int: f(n)

fn main:
    let l = log_new()
    let d = Database.new(l, 1).unwrap()
    print(f"{d.exec(invoke, n => n + 1, 1)}")
    log_free(l)
