//! expect-error: non-exhaustive match

error ParseError = Bad
error IoError = NotFound
error AppError from IoError, ParseError

fn describe(e: AppError) -> i32:
    match e:
        .Io(_) => 1

fn main:
    print(describe(AppError.Io(IoError.NotFound)))
