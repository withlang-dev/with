//! expect-stdout: 6
//! expect-stdout: 10

// P4.1 verification: custom iterator type implementing Iter[T] with
// mut self: Self next, used in both for-loop and manual while-loop.

type CountUp { current: i32, limit: i32 }

fn CountUp.new(limit: i32) -> CountUp:
    CountUp { current: 0, limit: limit }

impl Iter[i32] for CountUp:    fn next(mut self:
    Self) -> Option[i32]:
        if self.current >= self.limit:
            return .None
        let val = self.current
        self.current = self.current + 1
        .Some(val)

fn main:
    // Test 1: custom iterator in a for loop
    let iter = CountUp.new(4)
    var sum = 0
    for x in iter:
        sum = sum + x
    print(int_to_string(sum as i64))

    // Test 2: manual while-loop with next()
    let iter2 = CountUp.new(5)
    var sum2 = 0
    var done = false
    while not done:
        let item = iter2.next()
        if item.is_some():
            sum2 = sum2 + item.unwrap()
        else:
            done = true
    print(int_to_string(sum2 as i64))
