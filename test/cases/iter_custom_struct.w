// Test: custom iterator structs with complex next() methods
type StepRange = {
    current: i32,
    end_val: i32,
    step: i32
}

impl StepRange =
    fn next(self: *mut StepRange) -> ?i32:
        if self.current < self.end_val:
            let v = self.current
            self.current = self.current + self.step
            Some(v)
        else
            None

type Repeat = {
    value: i32,
    remaining: i32
}

impl Repeat =
    fn next(self: *mut Repeat) -> ?i32:
        if self.remaining > 0:
            self.remaining = self.remaining - 1
            Some(self.value)
        else
            None

type Collatz = {
    n: i32,
    done: bool
}

impl Collatz =
    fn next(self: *mut Collatz) -> ?i32:
        if self.done:
            None
        else
            let val = self.n
            if self.n == 1:
                self.done = true
            else if self.n % 2 == 0:
                self.n = self.n / 2
            else
                self.n = self.n * 3 + 1
            Some(val)

fn main -> i32:
    // StepRange: 0, 2, 4, 6, 8
    var sr = StepRange { current: 0, end_val: 10, step: 2 }
    var sum1: i32 = 0
    var count1: i32 = 0
    for x in sr:
        sum1 += x
        count1 += 1
    assert(sum1 == 20)
    assert(count1 == 5)

    // StepRange: 1, 4, 7
    var sr2 = StepRange { current: 1, end_val: 10, step: 3 }
    var sum2: i32 = 0
    for x in sr2:
        sum2 += x
    assert(sum2 == 12)

    // Repeat: 42 repeated 5 times
    var rep = Repeat { value: 42, remaining: 5 }
    var sum3: i32 = 0
    var count3: i32 = 0
    for x in rep:
        sum3 += x
        count3 += 1
    assert(sum3 == 210)
    assert(count3 == 5)

    // Collatz sequence starting at 6: 6, 3, 10, 5, 16, 8, 4, 2, 1
    var col = Collatz { n: 6, done: false }
    var steps: i32 = 0
    var last_val: i32 = 0
    for x in col:
        steps += 1
        last_val = x
    assert(steps == 9)
    assert(last_val == 1)

    println("all iter_custom_struct tests passed")
