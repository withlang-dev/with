//! expect-check-fail: global `h` binds a view into a temporary `List[Handle]` that is freed when this statement ends
// D174: an unannotated global is an unannotated binding. A resource has
// identity (D111), so its element is never copied out of a list that dies
// when the initializer ends; the view is refused, as a local's is.
type Handle { id: i32 }

impl Drop for Handle:
    move fn drop(): print(f"drop {self.id}")

fn handles() -> List[Handle]:
    var xs: List[Handle] = List.new()
    xs.push(Handle { id: 1 })
    xs

let h = handles()[0]

fn main:
    print(f"{h.id}")
