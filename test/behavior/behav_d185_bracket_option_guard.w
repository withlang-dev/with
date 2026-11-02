//! expect-stdout: Some("ann!")
//! expect-stdout: None
//! expect-stdout: None
//! expect-stdout: ran bob
// §13.6a (D185): a guard between clauses; a false guard yields None. The
// statement form (`for a in x; b in y:` with a body) stays: it runs the
// body only when every clause succeeds and builds nothing.
type User { name: str, active: bool }
fn get_user(id: i32) -> Option[User]: if id > 0: Some(User { name: if id == 1: "ann" ++ "" else: "bob" ++ "", active: id == 1 }) else: None
fn get_profile(u: User) -> Option[str]: Some(u.name ++ "!")
fn main:
    let a = [profile for user in get_user(1) if user.active for profile in get_profile(user)]
    print(f"{a:?}")
    let b = [profile for user in get_user(2) if user.active for profile in get_profile(user)]
    print(f"{b:?}")
    let c = [profile for user in get_user(0) if user.active for profile in get_profile(user)]
    print(f"{c:?}")
    for user in get_user(2); profile in get_profile(user):
        print(f"ran {user.name}")
