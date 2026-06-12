//! expect-check-fail: conditional move of Drop value requires drop-state tracking

type ConditionalMoveDropValue { id: str }
impl Drop for ConditionalMoveDropValue:
    fn drop(move self: Self):
        let _ = self.id

fn take_conditional_drop_value(v: ConditionalMoveDropValue): ()

fn main:
    let v = ConditionalMoveDropValue { id: "v" }
    if true:
        take_conditional_drop_value(v)
