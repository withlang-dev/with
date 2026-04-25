//! skip
// Spec test: Section 10 — Error Handling (formerly 25.9)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

error ParseError = InvalidSyntax(pos: usize)
error IoError = NotFound(path: String)
error AppError from IoError, ParseError

// PASS: propagation with conversion
fn load(path: &str) -> Result[Ast, AppError]:
    let text = read_file(path)?        // IoError -> AppError
    parse(&text)?                      // ParseError -> AppError

// PASS: match converted error
fn handle(e: AppError):
    match e:
        AppError.Io(io)    => print(f"io: {io}")
        AppError.Parse(pe) => print(f"parse: {pe}")

// FAIL: non-exhaustive
fn bad(e: AppError):
    match e:
        AppError.Io(_) => ()          // ERROR: missing Parse
