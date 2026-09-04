use compiler.foundation.Ids

extern fn with_print_str(s: &str) -> Unit

fn main:
    let id = arena_id_from_raw(3)
    unsafe { with_print_str(f"raw={arena_id_raw(id)} valid={arena_id_is_valid(id)}\n") }
