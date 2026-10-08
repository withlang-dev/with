//! expect-stdout: 3 0 3 0
//! expect-stdout: 4 4 6 1
//! expect-stdout: 3 0
// #1974 (§3.8; D22: an eliminator does not change what the eliminated value
// is): `??`, `unwrap_or` and `unwrap_or_else` over an owned payload produce
// an owned value, and a `&T` parameter borrows it like any owned argument
// (`peek(make())`). The `&str` demand was pushed into the join and its owned
// payload arm refused: "`??` expression of type `str` cannot produce
// `&str`". A view payload keeps the view join, as before.

fn peek(s: &str) -> i64: s.len()
fn bump(n: &i64) -> i64: *n + 1

fn make(ok: bool) -> Result[str, i32]:
    if ok: Ok("abc") else: Err(7)

fn some(ok: bool) -> Option[str]:
    if ok: Some("abc") else: None

fn first(v: &Vec[str]) -> Option[&str]:
    if v.len() > 0: Some(v[0]) else: None

fn main:
    print(f"{peek(make(true) ?? "")} {peek(make(false) ?? "")} {peek(make(true).unwrap_or(""))} {peek(make(false).unwrap_or(""))}")
    let n: Option[i64] = Some(3)
    let none_n: Option[i64] = None
    print(f"{peek(some(false).unwrap_or_else(() => "four"))} {bump(n ?? 0)} {peek(make(false).unwrap_or_else((e) => "seven!"))} {bump(none_n ?? 0)}")
    var v: Vec[str] = Vec.new()
    v.push("xyz")
    let empty: Vec[str] = Vec.new()
    print(f"{peek(first(&v) ?? "")} {peek(first(&empty) ?? "")}")
