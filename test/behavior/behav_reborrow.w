//! expect-stdout: ok

type State {
    val: i32,
    count: i32,
}

fn State.increment(mut self: State):
    self.val = self.val + 1
    self.count = self.count + 1

fn State.update(mut self: State, n: i32):
    var i = 0
    while i < n:
        self.val = self.val + 1
        self.count = self.count + 1
        i = i + 1

fn test_mutating_receiver_basic:
    var s = State { val: 0, count: 0 }
    s.update(3)
    assert(s.val == 3)
    assert(s.count == 3)

fn State.double_increment(mut self: State):
    self.val = self.val + 1
    self.count = self.count + 1
    self.val = self.val + 1
    self.count = self.count + 1

fn test_mutating_receiver_chained:
    var s = State { val: 10, count: 0 }
    s.double_increment()
    assert(s.val == 12)
    assert(s.count == 2)

fn main:
    test_mutating_receiver_basic()
    test_mutating_receiver_chained()
    print("ok")
