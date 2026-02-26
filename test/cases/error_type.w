// Test error type declarations (desugared to enums)

error FileError =
    NotFound
    PermissionDenied

error ParseError =
    InvalidSyntax
    UnexpectedEof

fn check_file -> i32:
    let e: FileError = NotFound
    match e
        NotFound -> 1
        PermissionDenied -> 2

fn check_parse -> i32:
    let e: ParseError = UnexpectedEof
    match e
        InvalidSyntax -> 10
        UnexpectedEof -> 20

fn main -> i32:
    assert(check_file() == 1)
    assert(check_parse() == 20)
