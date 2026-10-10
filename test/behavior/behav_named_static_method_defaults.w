//! expect-stdout: ok

type Pads {}
fn Pads.open(preferred_id: u32 = 0, platform_managed: bool = false) -> i32:
    if platform_managed: 42 else: preferred_id as i32

type Digits { first: i32 }
fn Digits.make(a: i32, b: i32, c: i32 = 3) -> i32: a * 100 + b * 10 + c
fn Digits.combine(self: &Self, b: i32, c: i32 = 3) -> i32: self.first * 100 + b * 10 + c

var calls: i32 = 0
fn next -> i32:
    calls += 1
    calls
fn Pads.count(value: i32 = next(), add: i32 = 0) -> i32: value + add

type Multiplier { value: i32 }
fn Pads.scaled(value: i32 = 2, add: i32 = 0, ctx: implicit &Multiplier) -> i32: value * ctx.value + add
fn Digits.scaled(self: &Self, add: i32 = 0, ctx: implicit &Multiplier) -> i32: self.first * ctx.value + add

fn main:
    assert(Pads.open(platform_managed: true) == 42)
    assert(Pads.open(platform_managed: false, preferred_id: 7) == 7)
    assert(Digits.make(c: 6, a: 4, b: 5) == 456)
    assert(Digits.make(1, c: 5, b: 2) == 125)
    assert(Digits.make(b: 2, a: 1) == 123)
    let digits = Digits { first: 1 }
    assert(digits.combine(c: 4, b: 2) == 124)
    assert(digits.combine(b: 2) == 123)
    assert(Pads.count(add: 100) == 101)
    assert(Pads.count(add: 100) == 102)
    with context(Multiplier { value: 3 }):
        assert(Pads.scaled(add: 4) == 10)
        assert(digits.scaled(add: 4) == 7)
    print("ok")
