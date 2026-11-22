//! expect-stdout: 3 7 9
// D144: a binding from a place of plain bits takes the value, an element as
// a field. `let k = self.starts[0]` stayed a view of the element (D27), so
// a mutating call on `self` while `k` was live was refused ("cannot mutate
// `self` while `k` is a live view into it"); `let k = self.idx` was already
// the value. Writing the list after the binding leaves `k` unchanged.
type T:
    idx: i32
    starts: List[i32]
    log: List[str]

impl T:
    mut fn note(m: str): self.log.push(m)
    mut fn element() -> i32:
        let k = self.starts[0]
        self.note("x")
        self.starts[0] = 9
        k

fn main:
    var t = T { idx: 7, starts: [3], log: [] }
    let first = t.element()
    let i = t.idx
    t.idx = 8
    print(f"{first} {i} {t.starts[0]}")
