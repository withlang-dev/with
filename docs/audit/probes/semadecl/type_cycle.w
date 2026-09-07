// SemaDecl probe: value-type cycle A<->B (check_type_cycles L956-1090)
type CycA {
    b: CycB,
}

type CycB {
    a: CycA,
}
