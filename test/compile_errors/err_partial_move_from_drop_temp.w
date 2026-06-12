//! expect-check-fail: partial move from Drop type

type DropTempChild { id: str }
impl Drop for DropTempChild:
    fn drop(move self: Self):
        let _ = self.id

type DropTempWrapper { child: DropTempChild }
impl Drop for DropTempWrapper:
    fn drop(move self: Self): ()

fn make_drop_temp_wrapper -> DropTempWrapper:
    DropTempWrapper { child: DropTempChild { id: "child" } }

fn main:
    let child = make_drop_temp_wrapper().child
