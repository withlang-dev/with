//! expect-check-fail: is a live view into it
// D144: the observing binding is a view of the field; assigning the field
// while it is live is refused like any other conflict with a live view.
type Holder { current: Option[List[i32]] }
impl Holder:
    mut fn reset():
        match self.current:
            Some(c) =>
                self.current = None
                c.push(1)
            None => ()
fn main:
    var h = Holder { current: Some([1]) }
    h.reset()
