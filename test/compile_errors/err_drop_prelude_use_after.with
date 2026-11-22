//! expect-check-fail: use of moved value

type DropPreludeMoved { id: i32 }
impl Drop for DropPreludeMoved:
    fn drop(move self: Self):
        let _ = self.id

fn main:
    let value = DropPreludeMoved { id: 7 }
    drop(value)
    let _ = value.id
