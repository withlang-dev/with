//! expect-check-fail: use of moved value

// #3461 (§9.7): a list of resources moved into a list pattern is gone.
type Tag { name: str }
impl Drop for Tag:
    move fn drop(): print(f"drop {self.name}")

fn f(xs: List[Tag]) -> i32:
    match move xs:
        [h, ..rest] => print(h.name)
        [] => print("none")
    xs.len() as i32

fn main: print(f([Tag { name: "a" }]))
