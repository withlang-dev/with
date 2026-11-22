//! expect-check-fail: does not implement trait 'Error'

type PlainError {
    code: i32
}

fn describe_error[E: Error](e: &E) -> str:
    e.display()

fn main:
    let plain = PlainError { code: 7 }
    let _ = describe_error(&plain)
