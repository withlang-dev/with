// T13 arena OOB + T23 wrong-kind/overflow directions.
use compiler.foundation.Ids
use compiler.foundation.Arena

extern fn with_print_str(s: &str) -> Unit

fn main:
    var a = Arena.init()
    unsafe { with_print_str(f"init_len={a.len()} contains0={a.contains(arena_id_from_raw(0))}\n") }
    let bad = arena_id_invalid()
    unsafe { with_print_str(f"containsNeg1={a.contains(bad)} kindNeg1={a.kind(bad)} getNeg1={a.get_i32(bad)}\n") }
    let i = a.alloc_i32(42)
    let st = a.alloc_str("hi")
    unsafe { with_print_str(f"i_raw={arena_id_raw(i)} st_raw={arena_id_raw(st)} len={a.len()}\n") }
    unsafe { with_print_str(f"get_i={a.get_i32(i)} get_str_i=[{a.get_str(i)}] get_s=[{a.get_str(st)}] get_i32_s={a.get_i32(st)}\n") }
    // OOB past end
    let oob = arena_id_from_raw(9999)
    unsafe { with_print_str(f"containsOOB={a.contains(oob)} kindOOB={a.kind(oob)} getOOB={a.get_i32(oob)} strOOB=[{a.get_str(oob)}]\n") }
    // reset is bulk-only
    a.reset()
    unsafe { with_print_str(f"after_reset_len={a.len()} contains_i={a.contains(i)}\n") }
    let j = a.alloc_i32(7)
    unsafe { with_print_str(f"realloc_raw={arena_id_raw(j)} get={a.get_i32(j)}\n") }
