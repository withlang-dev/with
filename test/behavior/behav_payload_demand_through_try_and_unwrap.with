//! expect-stdout: 43
//! expect-stdout: 44
//! expect-stdout: 45
//! expect-stdout: 2.5
//! expect-stdout: 45
//! expect-stdout: none
// A call whose result type nothing else decides takes the demand on its
// payload: `x?`, `x.unwrap()` and `x.expect(m)` under an expected type ask
// `x` for a carrier of that type, as `x ?? d` does (#959). Each line was
// "cannot infer generic method type parameter 'T'".
fn through_try(s: &str) -> Option[i32]:
    let n: i32 = s.parse()?
    Some(n + 3)

fn main:
    let s = "42"
    let a: i32 = s.parse().unwrap()
    print(a + 1)
    let b: i64 = s.parse().expect("a number")
    print(b + 2)
    let c: i32 = s.parse() ?? 0
    print(c + 3)
    let d: f64 = "2.5".parse().unwrap()
    print(d)
    print(through_try(s).unwrap())
    let bad: Option[i32] = through_try("x")
    if bad.is_none(): print("none")
