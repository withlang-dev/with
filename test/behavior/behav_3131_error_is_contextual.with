//! expect-stdout: timeout 504 bad gateway

// #3131 (§29.11): `error` opens a declaration only before a name. As a
// binding, a field and a parameter it is an ordinary identifier.

error Failure =
    | Status(code: i32)

error Other =
    | Gone

type Response { status: i32, error: str }

fn describe(error: str) -> str: error ++ " gateway"

fn check(r: &Response) -> Result[i32, Failure]:
    if r.status >= 500: return Err(.Status(r.status))
    r.status

fn main:
    let r = Response { status: 504, error: "timeout" }
    let error = describe("bad")
    let code = match check(r):
        Err(Failure.Status(c)) => c
        Ok(c) => c
    print(f"{r.error} {code} {error}")
