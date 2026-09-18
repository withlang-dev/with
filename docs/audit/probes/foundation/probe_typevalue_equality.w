// T8 type/value equality via canonical strings + T23 canon-collision check.
use compiler.foundation.Ids
use compiler.foundation.Types
use compiler.foundation.Values
use compiler.foundation.InternPool

extern fn with_print_str(s: &str) -> Unit

fn main:
    var p = InternPool.init()
    let t1 = p.intern_type(type_key_named("i32"))
    let t2 = p.intern_type(type_key_named("i32"))
    let t3 = p.intern_type(type_key_named("str"))
    unsafe { with_print_str(f"t1={type_id_raw(t1)} t2={type_id_raw(t2)} same={t1 == t2} t3={type_id_raw(t3)}\n") }
    // ptr vs ref vs named with crafted ":" names must NOT collide (tag-prefixed canons)
    let ptr = p.intern_type(type_key_ptr(t1, false))
    let craft = p.intern_type(type_key_named("ptr:1:0"))
    unsafe { with_print_str(f"ptr={type_id_raw(ptr)} crafted={type_id_raw(craft)} noclide={ptr != craft}\n") }
    let rt = p.resolve_type(t1)
    unsafe { with_print_str(f"resolve_tag={rt.tag} resolve_name=[{rt.name}] bad_tag={p.resolve_type(type_id_invalid()).tag} oob_tag={p.resolve_type(type_id_from_raw(9999)).tag}\n") }
    // values: int true dup stable; string "bool:1" must not collide with bool true
    let v1 = p.intern_value(value_key_int(5))
    let v2 = p.intern_value(value_key_int(5))
    let vb = p.intern_value(value_key_bool(true))
    let vs = p.intern_value(value_key_string("bool:1"))
    unsafe { with_print_str(f"v1={value_id_raw(v1)} v2same={v1 == v2} vb={value_id_raw(vb)} vs={value_id_raw(vs)} strbool_noclide={vb != vs}\n") }
    let rv = p.resolve_value(v1)
    unsafe { with_print_str(f"vint_tag={rv.tag} vint={rv.int_value} bad_vtag={p.resolve_value(value_id_invalid()).tag} oob_vtag={p.resolve_value(value_id_from_raw(9999)).tag}\n") }
    unsafe { with_print_str(f"tcount={p.type_count()} vcount={p.value_count()}\n") }
