//! expect-stdout: ok

enum Status {  | Ok }
    | Warning(str)
    | Fatal(code: i32)

fn is_fatal_with_code(status: Status, expected: i32) -> bool:
    match status
        .Fatal(code) => code == expected
        _ => false

fn main:
    let status: Status = .Fatal(code: 99)
    assert(is_fatal_with_code(status, 99))
    println("ok")
