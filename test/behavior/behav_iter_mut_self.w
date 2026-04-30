//! expect-stdout: 10

// P4.1 verification: custom iterator type implementing Iter[T] with
// mut self: Self next.
//
// Manual while-loop iteration works. For-loop (`for x in iter`) does NOT —
// MIR lowering's generic iterator path calls mark_unsupported() and AST
// codegen has been removed, so `for x in custom_iter` is a compile error.
// See docs/p10-structural-sites-audit.md "P4.1 Verification" for details.

type CountUp { current: i32, limit: i32 }

fn CountUp.new(limit: i32) -> CountUp:
    CountUp { current: 0, limit: limit }

impl Iter[i32] for CountUp =
    fn next(mut self: Self) -> Option[i32]:
        if self.current >= self.limit:
            return .None
        let val = self.current
        self.current = self.current + 1
        .Some(val)

fn main:
    // Manual while-loop: works correctly with mut self: Self.
    let iter = CountUp.new(5)
    var sum = 0
    var done = false
    while not done:
        let item = iter.next()
        if item.is_some():
            sum = sum + item.unwrap()
        else:
            done = true
    print(int_to_string(sum as i64))
