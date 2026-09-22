//! expect-stdout: alice alice@example.com
//! expect-stdout: bob 3
//! expect-stdout: 4 5
//! expect-stdout: 1 4
//! expect-stdout: carol 9

// #1299: a NAMED struct pattern in `let` (`STRUCT_PAT := [ TYPE ] '{' ... '}'`,
// §29; "all pattern forms are available in let", §9.7) parses and binds
// exactly like the anonymous `let { name, email } = req` and a `match` arm's
// `Req { name, email }`: by value it consumes the subject, over `&req` it
// binds views.

type Req { name: str, email: str }
type Point { x: i32, y: i32 }
type Line { a: Point, b: Point }
type Tagged { tag: i32, at: Point }

fn take(req: Req) -> str:
    let Req { name, email } = req
    name ++ " " ++ email

fn borrow(req: &Req) -> str:
    let Req { name, .. } = req
    *name

fn main:
    print(take(Req { name: "alice", email: "alice@example.com" }))
    let req = Req { name: "bob", email: "b@b" }
    let Req { email, .. } = &req
    print(f"{borrow(&req)} {email.len()}")
    let p = Point { x: 4, y: 5 }
    let Point { x: px, y: py } = &p
    print(f"{*px} {*py}")
    let l = Line { a: Point { x: 1, y: 2 }, b: Point { x: 3, y: 4 } }
    let Line { a: Point { x, .. }, b } = l
    print(f"{x} {b.y}")
    let t = Tagged { tag: 9, at: Point { x: 0, y: 0 } }
    let Tagged { tag, .. } = t
    let owner = Req { name: "carol", email: "c@c" }
    let Req { name, email: _ } = owner
    print(f"{name} {tag}")
