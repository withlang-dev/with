//! expect-stdout: Ok(1)
//! expect-stdout: 9223372036854775807
//! expect-stdout: 250
//! expect-stdout: 2.5
//! expect-stdout: Ok(-3)
//! expect-stdout: 7
// #1856 (§4.2.1: an unsuffixed literal takes its context's type): a
// parameter an unsuffixed literal fixes is soft. The use that settles the
// binding decides it — `T = i64`, `u8`, `f64` — and the literal is typed
// at that type, exactly as in a typed binding (`let r: Result[f64, str] =
// Ok(3)`). Unsettled, it keeps the default `isize`.
fn wide(r: Result[i64, str]) -> i64: (r ?? 0) + 9223372036854775806
fn small(o: Option[u8]) -> u8: (o ?? 0) + 248
fn real(r: Result[f64, str]) -> f64: (r ?? 0.0) + 1.5
fn neg(r: Result[i16, str]): print(f"{r:?}")

fn main:
    let d = Ok(1)
    print(f"{d:?}")
    let unused_err: Result[i32, str] = d
    let a = Ok(1)
    print(wide(a))
    let o = Some(2)
    print(small(o))
    let f = Ok(1)
    print(real(f))
    let n = Ok(-3)
    neg(n)
    let x = Some(7)
    print(x ?? 0)
