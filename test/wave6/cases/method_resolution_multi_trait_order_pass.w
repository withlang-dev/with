// Wave 6: deterministic multi-trait method lookup order.

trait Left =
    fn pick(self: Self) -> i32

trait Right =
    fn pick(self: Self) -> i32

type Token = {
    value: i32,
}

impl Left for Token =
    fn pick(self: Token) -> i32:
        self.value + 10

impl Right for Token =
    fn pick(self: Token) -> i32:
        self.value + 20

fn main -> i32:
    let t = Token { value: 1 }
    let got = t.pick()
    assert(got == 11)
    got
