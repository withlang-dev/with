// T8 identity: id uniqueness, invalid sentinels, raw roundtrip, validity boundary.
use compiler.foundation.Ids

extern fn with_print_str(s: &str) -> Unit

fn main:
    unsafe { with_print_str(f"file_invalid={file_id_raw(file_id_invalid())} mod_invalid={module_id_raw(module_id_invalid())} def_invalid={def_id_raw(def_id_invalid())}\n") }
    unsafe { with_print_str(f"item_invalid={item_id_raw(item_id_invalid())} type_invalid={type_id_raw(type_id_invalid())} val_invalid={value_id_raw(value_id_invalid())}\n") }
    unsafe { with_print_str(f"sym_invalid={symbol_raw(symbol_invalid())} arena_invalid={arena_id_raw(arena_id_invalid())}\n") }
    // roundtrip
    let f = file_id_from_raw(7)
    unsafe { with_print_str(f"roundtrip7={file_id_raw(f)} valid7={file_id_is_valid(f)}\n") }
    unsafe { with_print_str(f"valid0={file_id_is_valid(file_id_from_raw(0))} validNeg1={file_id_is_valid(file_id_from_raw(-1))}\n") }
    // distinct domains are all i32 aliases: same raw in two domains compares equal as i32
    let a = arena_id_from_raw(5)
    let s = symbol_from_raw(5)
    unsafe { with_print_str(f"cross_domain_raw_eq={arena_id_raw(a) == symbol_raw(s)}\n") }
    // arena slot 0 reserved: is id 0 valid per predicate?
    unsafe { with_print_str(f"arena0_valid={arena_id_is_valid(arena_id_from_raw(0))}\n") }
