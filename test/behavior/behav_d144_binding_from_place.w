//! expect-stdout: 1 2
//! expect-stdout: 2 9
//! expect-stdout: 7 3

// D144: a binding from a place of a plain-bits type takes the value; any
// other binding from a place observes it. `let i = self.idx` snapshots the
// isize, so `self.idx += 1` after it is fine; `match self.current: Some(c)
// => c.push(9)` observes the List in place, so the push lands in the field
// (#2541); a plain-bits payload takes the value.
type Holder { current: Option[List[i32]], idx: isize, mark: Option[isize] }

impl Holder:
    mut fn snap() -> isize:
        let i = self.idx
        self.idx += 1
        i
    mut fn bump():
        match self.current:
            Some(c) => c.push(9)
            None => ()
    fn marked() -> isize:
        match self.mark:
            Some(n) => n + 2
            None => 0
    mut fn grow():
        let items = self.current
        match items:
            Some(c) => c.push(3)
            None => ()

fn main:
    var h = Holder { current: Some([1]), idx: 1, mark: Some(5) }
    print(f"{h.snap()} {h.idx}")
    h.bump()
    match h.current:
        Some(c) => print(f"{c.len()} {c[1]}")
        None => print("none")
    h.grow()
    var n = 0
    match h.current:
        Some(c) => n = c.len()
        None => ()
    print(f"{h.marked()} {n}")
