// SemaDecl probe: Copy+Drop conflict (collect_impl_decl L2232, L2267)
type CdBox {
    v: i32,
}

impl Drop for CdBox:
    fn drop(move self: Self):
        print("drop")

impl Copy for CdBox
