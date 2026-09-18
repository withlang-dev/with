// T5 negative control: view's last use precedes the move; must pass.
use std.builtins.print_i32

type W { id: i32 }
impl Drop for W:
    fn drop(move self: Self):
        print_i32(self.id)

type Holder { item: W }

fn main:
    var holder = Holder { item: W { id: 7 } }
    let v = &holder.item.id
    print_i32(*v)
    let moved = move holder.item
    print_i32(moved.id)
