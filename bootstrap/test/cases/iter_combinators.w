// Test: Iterator combinators and composition
// Demonstrates building iterator adapters with the next() protocol

// A range iterator
type Range = {
    current: i32,
    end_val: i32
}

impl Range =
    fn next(self: *mut Range) -> ?i32:
        if self.current < self.end_val:
            let v = self.current
            self.current = self.current + 1
            Some(v)
        else
            None

// Manual fold: sum elements of an iterator
fn fold_sum(start: i32, end_val: i32) -> i32:
    var r = Range { current: start, end_val: end_val }
    var acc = 0
    for x in r:
        acc = acc + x
    acc

// Manual count: count elements
fn count_range(start: i32, end_val: i32) -> i32:
    var r = Range { current: start, end_val: end_val }
    var n = 0
    for x in r:
        n = n + 1
    n

// Manual filter+count: count even numbers
fn count_even(start: i32, end_val: i32) -> i32:
    var r = Range { current: start, end_val: end_val }
    var n = 0
    for x in r:
        if x % 2 == 0:
            n = n + 1
    n

// Manual map+sum: sum of squares
fn sum_squares(start: i32, end_val: i32) -> i32:
    var r = Range { current: start, end_val: end_val }
    var acc = 0
    for x in r:
        acc = acc + x * x
    acc

// Countdown iterator (demonstrates different iteration pattern)
type Countdown = {
    value: i32
}

impl Countdown =
    fn next(self: *mut Countdown) -> ?i32:
        if self.value > 0:
            self.value = self.value - 1
            Some(self.value + 1)
        else
            None

// Fibonacci iterator
type Fib = {
    a: i32,
    b: i32,
    remaining: i32
}

impl Fib =
    fn next(self: *mut Fib) -> ?i32:
        if self.remaining > 0:
            let val = self.a
            let temp = self.a + self.b
            self.a = self.b
            self.b = temp
            self.remaining = self.remaining - 1
            Some(val)
        else
            None

fn main -> i32:
    // fold: sum 0..5 = 0+1+2+3+4 = 10
    assert(fold_sum(0, 5) == 10)

    // fold: sum 1..11 = 55
    assert(fold_sum(1, 11) == 55)

    // count: 0..5 has 5 elements
    assert(count_range(0, 5) == 5)

    // filter: even numbers in 0..10 = {0,2,4,6,8} = 5
    assert(count_even(0, 10) == 5)

    // map: sum of squares 1..4 = 1+4+9 = 14
    assert(sum_squares(1, 4) == 14)

    // Countdown iterator
    var cd = Countdown { value: 3 }
    var cd_sum = 0
    for x in cd:
        cd_sum = cd_sum + x
    assert(cd_sum == 6)

    // Fibonacci iterator: first 7 fib numbers
    var fib = Fib { a: 0, b: 1, remaining: 7 }
    var fib_sum = 0
    for x in fib:
        fib_sum = fib_sum + x
    // 0+1+1+2+3+5+8 = 20
    assert(fib_sum == 20)

    // Nested iteration: use two ranges
    var outer_sum = 0
    var r1 = Range { current: 1, end_val: 4 }
    for i in r1:
        var r2 = Range { current: 1, end_val: 4 }
        for j in r2:
            outer_sum = outer_sum + i * j
    // (1+2+3) * (1+2+3) = 36
    assert(outer_sum == 36)

    println("all iterator combinator tests passed")
