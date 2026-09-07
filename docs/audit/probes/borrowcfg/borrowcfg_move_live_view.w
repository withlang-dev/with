// T5 fire: moving a place while a view into it is still live.
use std.builtins.print_i32

type W { id: i32 }
impl Drop for W:
    fn drop(move self: Self):
        print_i32(self.id)

type Holder { item: W }

fn main:
    var holder = Holder { item: W { id: 7 } }
    let v = &holder.item.id
    let moved = move holder.item
    print_i32(*v + moved.id)
