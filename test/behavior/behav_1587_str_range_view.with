//! expect-stdout: hello
//! expect-stdout: world
//! expect-stdout: ell
//! expect-stdout: 12
//! expect-stdout: yes
//! expect-stdout: orld
//! expect-stdout: hello
//! expect-stdout: 3
//! expect-stdout: 0

// #1587 / D71 (§4.8a): a range of a `str` or `&str` — `s[a..b]`, `s[a..]`,
// `s[..b]`, `s[..]` — is a `&str` view of its bytes with the origin of any
// view. It used to fail generic inference (`print(s[2..])`) or hand MIR a
// valueless expression (`let t: str = s[2..]`: "invalid MIR before codegen").
// A range through a reference slices what it names (§3.7): `a[1..]` on a
// `&[4]i32` parameter failed codegen ("slice base has no bounds metadata").

fn head(s: &str): print(s[..5])
fn rest_len(a: &[4]i32): print(a[1..].len())

fn main:
    let s = "hello, world"
    print(s[..5])
    print(s[7..])
    let mid = s[1..4]
    print(mid)
    print(s[..].len())
    if s[..5] == "hello": print("yes")
    let r: &str = s[7..]
    print(r[1..])
    head(s)
    let a = [1, 2, 3, 4]
    rest_len(a)
    print(s[3..3].len())
