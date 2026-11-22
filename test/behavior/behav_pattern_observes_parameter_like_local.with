//! expect-stdout: saw param
//! expect-stdout: after match (parameter)
//! expect-stdout: again param
//! expect-stdout: drop param
//! expect-stdout: saw local
//! expect-stdout: after match (local)
//! expect-stdout: drop local
//! expect-stdout: kept moved
//! expect-stdout: drop moved
//! expect-stdout: after move

// §9.7 (D115; Eric, 2026-11-20): an owned subject is a temporary or a
// place moved with `move`. A by-value parameter is a place, as a local is:
// the same `match m` observes either, the value drops at the end of the
// function, and it may be used after the match. `match move m` takes it
// apart. (A parameter used to be taken apart by a bare `match m`, so
// moving the code between a function and its caller changed when the
// payload was dropped and what compiled.)
type Tag { name: str }
impl Drop for Tag:
    move fn drop(): print(f"drop {self.name}")

enum Msg:
    Text(t: Tag)
    Empty

fn keep(t: Tag): print(f"kept {t.name}")

fn by_parameter(m: Msg):
    match m:
        .Text(t) => print(f"saw {t.name}")
        .Empty => print("empty")
    print("after match (parameter)")
    if let .Text(t) = m: print(f"again {t.name}")

fn by_local:
    let m = Msg.Text(Tag { name: "local" })
    match m:
        .Text(t) => print(f"saw {t.name}")
        .Empty => print("empty")
    print("after match (local)")

fn taken(m: Msg):
    match move m:
        .Text(t) => keep(t)
        .Empty => print("empty")
    print("after move")

fn main:
    by_parameter(Msg.Text(Tag { name: "param" }))
    by_local()
    taken(Msg.Text(Tag { name: "moved" }))
