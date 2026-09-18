// SemaDecl probe: impl of unknown trait (collect_impl_decl L2213)
type OrphanT {
    v: i32,
}

impl NoSuchTraitHere for OrphanT:
    fn missing(move self: Self):
        print("x")
