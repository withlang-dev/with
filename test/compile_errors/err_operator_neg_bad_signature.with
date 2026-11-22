//! expect-check-fail: operator '-' has no applicable 'neg' implementation

type BadNeg { value: i32 }

impl BadNeg:
    fn neg(self: &Self, extra: i32) -> BadNeg:
        BadNeg { value: -self.value + extra }

fn main:
    let _ = -BadNeg { value: 1 }
