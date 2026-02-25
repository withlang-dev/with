// Test while-let loops

type Range = { current: i32, end_val: i32 }

impl Range
    fn next(self: *mut Range) -> ?i32 =
        if self.current < self.end_val:
            let v = self.current
            self.current = self.current + 1
            Some(v)
        else
            None

fn main() -> i32 =
    var r = Range { current: 0, end_val: 5 }
    var sum = 0
    while let Some(x) = r.next():
        sum = sum + x
    assert(sum == 10)
    0
