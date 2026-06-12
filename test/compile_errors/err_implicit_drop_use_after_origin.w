//! expect-check-fail: implicit drop of `holder` uses `&x` after `x` is destroyed

type Rule7Holder = ephemeral { view: &i32 }
impl Drop for Rule7Holder:
    fn drop(move self: Self):
        let _ = self.view

fn main:
    let root = 0
    var holder = Rule7Holder { view: &root }
    let x = 1
    holder = Rule7Holder { view: &x }
