//! expect-stdout: Some("ann!?")
//! expect-stdout: None
//! expect-stdout: Ok(4)
//! expect-stdout: Err("bad")
//! expect-stdout: Ok("r1r1")

// §13.6a (D185): a bracket comprehension over an Option or Result first
// clause is the short-circuiting chain: the element re-wraps in the
// comprehension's own carrier (Some/Ok of the element's type, the Err type
// the clauses share), and a failing clause passes None or its Err through.
// The spec's own example (`User` -> profile -> `str`) once did not compile:
// the failure arm re-returned the clause's value, which joined only when
// the element kept the payload's type.

type User { name: str }

fn get_user(id: i32) -> Option[User]: if id > 0: Some(User { name: "ann" ++ "" }) else: None
fn get_profile(u: User) -> Option[str]: Some(u.name ++ "!")
fn parse(s: str) -> Result[i64, str]: if s.len() > 0: Ok(s.len()) else: Err("bad" ++ "")
fn res(b: bool) -> Result[str, str]: if b: Ok("r" ++ "1") else: Err("e" ++ "1")

fn main:
    let name: Option[str] = [profile ++ "?" for user in get_user(1) for profile in get_profile(user)]
    print(f"{name:?}")
    let missing: Option[str] = [profile ++ "?" for user in get_user(0) for profile in get_profile(user)]
    print(f"{missing:?}")
    let total = [a + b for a in parse("ab") for b in parse("cd")]
    print(f"{total:?}")
    let failed = [a + b for a in parse("ab") for b in parse("")]
    print(f"{failed:?}")
    let joined = [a ++ b for a in res(true) for b in res(true)]
    print(f"{joined:?}")
