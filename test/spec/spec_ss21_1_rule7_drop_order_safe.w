//! expect-stdout: ok

type Rule7SafeHolder = ephemeral { view: &i32 }
impl Drop for Rule7SafeHolder:
    fn drop(move self: Self):
        let _ = self.view

fn main:
    let x = 1
    let holder = Rule7SafeHolder { view: &x }
    let _ = holder.view
    print("ok")
