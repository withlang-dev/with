// SemaDecl probe NEGATIVE: pointer indirection breaks cycle
type PtrA {
    b: *PtrB,
}

type PtrB {
    a: PtrA,
}

fn main:
    print("cycle-pointer ok")
