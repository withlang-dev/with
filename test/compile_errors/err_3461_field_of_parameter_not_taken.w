//! expect-check-fail: a field never moves out implicitly (§2.2, D32)

// §9.7: a field of a by-value parameter has an owned root, so a pattern
// would take it apart; taking one field out of an owner that has a
// destructor is the partial move §2.2 refuses.
type Tag { name: str }
impl Drop for Tag:
    move fn drop(): print(f"drop {self.name}")

type P { items: List[Tag], n: i32 }
impl Drop for P:
    move fn drop(): print("drop P")

fn f(p: P) -> i32:
    match p.items:
        [h, ..rest] => print(f"head {h.name} rest {rest.len()}")
        [] => print("none")
    p.n

fn main: print(f(P { items: [Tag { name: "a" }], n: 7 }))
