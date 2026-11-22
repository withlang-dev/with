//! expect-stdout: ok

type Rc { value: i32 }
type Arc { value: i32 }

impl Rc:
    fn value_plus_one(self: &Self) -> i32:
        self.value + 1

impl Arc:
    fn value_plus_two(self: &Self) -> i32:
        self.value + 2

fn main:
    let rc = Rc { value: 10 }
    let arc = Arc { value: 20 }
    assert(rc.value_plus_one() == 11)
    assert(arc.value_plus_two() == 22)
    print("ok")
