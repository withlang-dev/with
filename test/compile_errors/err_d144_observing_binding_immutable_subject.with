//! expect-check-fail: cannot mutate through read-only view
// D144: an observing binding into an immutable subject is refused a
// mutating call; a copy is spelled.
type Holder { current: Option[List[i32]] }
impl Holder:
    fn peek_push():
        match self.current:
            Some(c) => c.push(9)
            None => ()
fn main:
    let h = Holder { current: Some([1]) }
    h.peek_push()
