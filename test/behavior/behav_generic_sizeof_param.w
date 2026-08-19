//! expect-stdout: 42

// sizeof[T]() inside a monomorphized generic must see the instance
// substitution. The regression left the type-param ident unresolved at
// codegen (the emitter established no type-binding frame for the instance)
// and sizeof silently became 0, so the memcpy below copied nothing —
// arena_vec_push lost every element the same way.

use std.builtins.print_i32
extern fn with_memcpy(dst: *mut u8, src: *const u8, n: i64) -> *mut u8

type Slot[T] {
    ptr: *mut T,
}

pub unsafe fn slot_put[T](s: *mut Slot[T], value: T) -> Unit:
    with_memcpy((*s).ptr as *mut u8, &value as *const T as *const u8, sizeof[T]() as i64)

fn main:
    var storage: i32 = 0
    var slot: Slot[i32] = Slot { ptr: &raw mut storage }
    let sp = &raw mut slot as *mut Slot[i32]
    unsafe:
        slot_put(sp, 42)
    print_i32(storage)
