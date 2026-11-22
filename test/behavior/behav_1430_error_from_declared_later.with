//! expect-stdout: ok 3333333333333
//! expect-stdout: display none
//! expect-stdout: db failed code=1111111 detail=2222222222222
//! expect-stdout: display Db(Failed(1111111, 2222222222222))
//! expect-stdout: db missing users
//! expect-stdout: display Db(Missing(users))
//! expect-stdout: io closed 4444444444444
//! expect-stdout: ok

// #1430 / §10.9: `error AppError from DbError, IoFail` above the errors it
// wraps. Its generated wrapper variants carry DbError and IoFail by value, and
// the wrapper enum was laid out before their bodies existed: the payload was
// truncated to nothing and generating AppError's Display aborted ("no payload
// value for enum type ... while formatting"). A facade's generated <R>Error is
// rendered after every user declaration, so this is the shape of composing a
// modeled C library's error (D51 stage 5). Both conversions go through `?`;
// every payload field and the generated Display are printed.

error AppError from DbError, IoFail

fn query(fail: i32) -> Result[i64, DbError]:
    if fail == 1:
        return Err(DbError.Failed(1111111, 2222222222222))
    if fail == 2:
        return Err(DbError.Missing("users"))
    Ok(3333333333333)

fn run(fail: i32) -> Result[i64, AppError]:
    let v = query(fail)?
    Ok(v)

fn show(fail: i32):
    match run(fail):
        Ok(v) => print(f"ok {v}")
        Err(AppError.Db(DbError.Failed(code, detail))) => print(f"db failed code={code} detail={detail}")
        Err(AppError.Db(DbError.Missing(what))) => print(f"db missing {what}")
        Err(e) => print(f"other {e}")
    match run(fail):
        Err(e) => print(f"display {e}")
        Ok(_) => print("display none")

fn close(fd: i64) -> Result[i64, IoFail]: Err(IoFail.Closed(fd))

fn run_io(fd: i64) -> Result[i64, AppError]:
    let v = close(fd)?
    Ok(v)

fn main:
    show(0)
    show(1)
    show(2)
    match run_io(4444444444444):
        Err(AppError.IoFail(IoFail.Closed(fd))) => print(f"io closed {fd}")
        Err(e) => print(f"io other {e}")
        Ok(v) => print(f"io ok {v}")
    print("ok")

error DbError =
    | Failed(code: i32, detail: i64)
    | Missing(what: str)

error IoFail =
    | Closed(fd: i64)
