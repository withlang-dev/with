// Wave 7: cleanup/defer CFG shape with early return.

type Guard = {
    id: i32,
}

impl Drop for Guard =
    fn drop(mut self: Guard):
        let _ = self.id

fn touch(x: i32) -> i32:
    x

fn worker(x: i32) -> i32:
    let g = Guard { id: x }
    defer touch(x + 1)

    if x > 0:
        return x

    g.id + 2

fn main -> i32:
    assert(worker(1) == 1)
    assert(worker(0) == 2)
    0
