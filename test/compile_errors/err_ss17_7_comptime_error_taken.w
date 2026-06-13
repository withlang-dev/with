//! expect-check-fail: is not serializable

type Handle { value: i32 }

impl Drop for Handle:
    fn drop(move self: Self):
        let _ = self.value

fn serialize[T](val: T) -> i32:
    let _ = val
    comptime if T.is_copy():
        1
    else:
        comptime_error("is not serializable")

fn main:
    serialize(Handle { value: 1 })
