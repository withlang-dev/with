// SemaDecl probe NEGATIVE: Copy over all-Copy fields is fine
type CopyOk {
    v: i32,
}

impl Copy for CopyOk

fn main:
    let c = CopyOk { v: 7, }
    let d = c
    assert(d.v == 7)
