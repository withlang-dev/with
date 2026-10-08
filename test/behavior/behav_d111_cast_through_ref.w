//! expect-stdout: ada ada bob

// D111 with D75 (§4.5): a cast through a reference stays a view of the
// source place; where an owned str is demanded (a return, a push) it is
// copied with its own hold, so overwriting the source leaves the copies.
type Name = distinct str
fn own(n: &Name) -> str: n as str
fn view(n: &Name) -> &str: n as str
fn main:
    var n = ("ad" ++ "a") as Name
    let a = own(&n)
    var v: Vec[str] = Vec.new()
    v.push(&n as str)
    n = "bob" as Name
    print(f"{a} {v[0]} {view(&n)}")
