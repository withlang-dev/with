// Wave 7: drop placement across loop continue paths.

type Guard = {
    id: i32,
}

impl Drop for Guard =
    fn drop(mut self: Guard):
        let _ = self.id

fn make_guard(id: i32) -> Guard:
    Guard { id: id }

fn run(limit: i32) -> i32:
    let mut i = 0
    let mut sum = 0
    while i < limit:
        let g = make_guard(i)
        if i % 2 == 0:
            i = i + 1
            continue
        sum = sum + g.id
        i = i + 1
    sum

fn main -> i32:
    assert(run(5) == 4)
    0
