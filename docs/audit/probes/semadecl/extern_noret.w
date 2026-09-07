// SemaDecl probe: extern fn without return ann defaults to Unit (collect_extern_fn L1655)
extern fn semadecl_probe_no_ret(x: i32)

fn main:
    print("extern-noret ok")
