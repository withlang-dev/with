// SemaDecl probe: disc-enum discriminant out of range (collect_type_decl L789-791)
enum BadRepr: i8:
    A = 127
    B = 100
    C = 200
