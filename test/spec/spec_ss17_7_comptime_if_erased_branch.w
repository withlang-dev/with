//! expect-stdout: ok

trait Named:
    fn name(self: &Self) -> str

type Person { name: str }
type Plain: Copy { value: i32 }

impl Named for Person:
    fn name(self: &Self) -> str:
        self.name

fn describe[T](val: T) -> i32:
    comptime if T.implements(Named):
        1
    else if T.is_copy():
        2
    else:
        val.missing_method_xyz()

fn main:
    assert(describe(Person { name: "Ada" }) == 1)
    assert(describe(Plain { value: 3 }) == 2)
    print("ok")
