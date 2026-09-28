//! expect-stdout: Some("ann!?")
//! expect-stdout: None
//! expect-stdout: Ok(4)
//! expect-stdout: Err("bad")
//! expect-stdout: Ok("r1r1")

// §13.6a: the yield form re-wraps its value in the comprehension's own
// carrier — Some/Ok of the yielded type, the Err type the clauses share —
// and a failing clause passes None or its Err through. The spec's own
// example (`User` -> profile -> `str`) did not compile: the failure arm
// re-returned the clause's value, which joined only when the yield kept the
// payload's type, and an unannotated Result yield was typed as an Option.

type User { name: str }

fn get_user(id: i32) -> Option[User]: if id > 0: Some(User { name: "ann" ++ "" }) else: None
fn get_profile(u: User) -> Option[str]: Some(u.name ++ "!")
fn parse(s: str) -> Result[i64, str]: if s.len() > 0: Ok(s.len()) else: Err("bad" ++ "")
fn res(b: bool) -> Result[str, str]: if b: Ok("r" ++ "1") else: Err("e" ++ "1")

fn main:
    let name: Option[str] =
        for user in get_user(1);
            profile in get_profile(user):
        yield profile ++ "?"
    print(f"{name:?}")
    let missing: Option[str] =
        for user in get_user(0);
            profile in get_profile(user):
        yield profile ++ "?"
    print(f"{missing:?}")
    let total = for a in parse("ab"); b in parse("cd"): yield a + b
    print(f"{total:?}")
    let failed = for a in parse("ab"); b in parse(""): yield a + b
    print(f"{failed:?}")
    let joined = for a in res(true); b in res(true): yield a ++ b
    print(f"{joined:?}")
