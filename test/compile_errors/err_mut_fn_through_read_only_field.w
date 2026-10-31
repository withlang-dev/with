//! expect-error: `self.counter` is a read-only view (`&Counter`)

// D172 (§3.8a, §9): a `mut fn` whose write goes through a read-only view
// field is refused for the field, not for its receiver: `go` is already
// `mut fn`, so "declare it `mut fn go`" named the wrong fix.

type Counter { n: i32 }

impl Counter:
    mut fn bump(): self.n += 1

type Holder = ephemeral { counter: &Counter }

impl Holder:
    mut fn go(): self.counter.bump()

fn main:
    var c = Counter { n: 0 }
    var h = Holder { counter: c }
    h.go()
