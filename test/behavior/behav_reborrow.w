//! expect-stdout: ok

// Tests: exclusive-to-exclusive reborrowing (&mut self → helper taking &mut Self)

type State {
    val: i32,
    count: i32,
}

fn increment(s: &mut State):
    s.val = s.val + 1
    s.count = s.count + 1

fn State.update(self: &mut State, n: i32):
    var i = 0
    while i < n:
        increment(self)
        i = i + 1

fn test_reborrow_basic:
    var s = State { val: 0, count: 0 }
    s.update(3)
    assert(s.val == 3)
    assert(s.count == 3)

fn double_increment(s: &mut State):
    increment(s)
    increment(s)

fn test_reborrow_chained:
    var s = State { val: 10, count: 0 }
    double_increment(&mut s)
    assert(s.val == 12)
    assert(s.count == 2)

fn main:
    test_reborrow_basic()
    test_reborrow_chained()
    print("ok")
