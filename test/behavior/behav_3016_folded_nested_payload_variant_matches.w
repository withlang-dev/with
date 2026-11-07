//! expect-stdout: ok users 42
//! expect-stdout: ok users 42
//! expect-stdout: busy
//! expect-stdout: circle 7
//! expect-stdout: ok users 42
// #3016 (§17): the evaluator's variant constructor took its payload start
// before evaluating the arguments, so a nested payload variant's own extras
// sat between the start and the value, and a comptime
// `AppError.Db(DbError.NotFound("users", "42"))` came out as `.Db("users")`
// and matched nothing at run time. A constructor call written in a body is
// no longer folded (it is already its value); a `const` evaluates it.
enum DbError:
    NotFound(str, str)
    Busy
enum AppError:
    Db(DbError)
    Io
enum Shape:
    Circle(i32)
    Dot
const CIRCLE: Shape = .Circle(7)
fn describe(e: AppError) -> str:
    match e:
        .Db(.NotFound(a, b)) => f"ok {a} {b}"
        .Db(.Busy) => "busy"
        _ => "MISMATCH"
fn main:
    let g = AppError.Db(DbError.NotFound("users", "42"))
    print(describe(g))
    let h: AppError = .Db(.NotFound("users", "42"))
    print(describe(h))
    print(describe(AppError.Db(DbError.Busy)))
    match CIRCLE:
        .Circle(r) => print(f"circle {r}")
        .Dot => print("dot")
    print(describe(NESTED))

const NESTED: AppError = AppError.Db(DbError.NotFound("users", "42"))
