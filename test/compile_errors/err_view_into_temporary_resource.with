//! expect-check-fail: binds a view into a temporary `List[Handle]` that is freed when this statement ends (§21.1); bind the `List[Handle]` first, or take an owned value (`.clone()`)
// A view into a statement temporary is copied only when the viewed value is
// Copy. A resource has identity (D111): its element cannot be copied out of
// a list that dies with the statement, and a second owner is never made.
type Handle { id: i32 }

impl Drop for Handle:
    move fn drop(): print(f"drop {self.id}")

fn handles() -> List[Handle]:
    var xs: List[Handle] = List.new()
    xs.push(Handle { id: 1 })
    xs

fn main:
    let h = handles()[0]
    print(f"{h.id}")
