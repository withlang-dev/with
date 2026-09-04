// T22/spec §3.7 + §8 probe: as_ref/as_ptr/deref/auto-deref field all read 42.
use std.box.Box
use std.builtins.print_i32

type Wrapper { val: i32 }

fn main:
    let b = Box.new(42)
    print_i32(*b.as_ref())
    print_i32(unsafe { *b.as_ptr() })
    print_i32(*b.deref())
    let w = Box.new(Wrapper { val: 42 })
    print_i32(w.val)
