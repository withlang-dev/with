//! expect-stdout: ok

type Handle { value: i32 }

impl Drop for Handle:
    fn drop(move self: Self):
        let _ = self.value

fn pick[T](val: T) -> i32:
    let _ = val
    comptime if T.is_copy():
        1
    else:
        2

fn main:
    assert(pick(5) == 1)
    assert(pick(Handle { value: 9 }) == 2)
    print("ok")
