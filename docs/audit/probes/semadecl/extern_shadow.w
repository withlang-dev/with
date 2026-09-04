// SemaDecl probe: extern fn shadowing a local fn (collect_extern_fn L1606-1616)
fn semadecl_shadowed() -> i32:
    1

extern fn semadecl_shadowed() -> i32
