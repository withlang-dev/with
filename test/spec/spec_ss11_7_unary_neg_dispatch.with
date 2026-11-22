//! expect-stdout: ok

type Score { value: i32 }

impl Score:
    fn neg(self: &Self) -> Score:
        Score { value: -self.value }

fn negate_generic[T](value: T) -> T:
    -value

fn main:
    let x = Score { value: 7 }
    let y = -x
    assert(y.value == -7)

    let z = -(-Score { value: 3 })
    assert(z.value == 3)

    let g = negate_generic(Score { value: 11 })
    assert(g.value == -11)

    assert(-5 == -5)
    print("ok")
