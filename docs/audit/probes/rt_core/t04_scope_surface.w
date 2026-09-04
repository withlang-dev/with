// .audit/probes/rt_core/t04_scope_surface.w
// T4: touch the fiber/scope extern surface declared in rt_core.w
// (with_scope_create/destroy link against fiber stubs or fiber core).
extern fn with_scope_create() -> i64
extern fn with_scope_destroy(handle: i64) -> Unit
fn main:
    let h = with_scope_create()
    if h == 0:
        print("scope-create-null")
    else:
        with_scope_destroy(h)
        print("t04-scope-ok")
