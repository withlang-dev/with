error IoError = Disk
error AppError from IoError

fn f() -> Result[i32, IoError] = Err(Disk)

fn g() -> Result[i32, AppError] =
    let x = f()?
    x

fn main() -> i32 =
    let r = g()
    if r.is_err() then 0 else 1
