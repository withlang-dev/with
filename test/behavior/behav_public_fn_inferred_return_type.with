//! expect-stdout: ok

// §9.1: visibility does not change return inference. Exercise calls before
// declarations, public methods, generic specialization and a branching tail.
fn main:
    assert(exported_value() == 42)
    exported_unit()
    assert(exported_choice(true) == 7)
    assert(exported_choice(false) == 9)
    assert(exported_identity(13) == 13)
    var counter = PublicReturnCounter { value: 0 }
    counter.bump()
    assert(counter.read() == 1)
    print("ok")

pub fn exported_value:
    41 + 1

pub fn exported_unit:
    assert(true)

pub fn exported_choice(left: bool):
    if left: 7
    else: 9

pub fn exported_identity[T](value: T): value

pub type PublicReturnCounter { value: i32 }
impl PublicReturnCounter:
    pub mut fn bump(): self.value = self.value + 1
    pub fn read(): self.value
