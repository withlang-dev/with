var DROPS = 0

type Owned { value: i32 }
impl Drop for Owned:
    fn drop(move self: Self): DROPS = DROPS + self.value

fn make_owned(value: i32) -> Owned: Owned { value }

fn main:
    make_owned(1)
    assert(DROPS == 1)
