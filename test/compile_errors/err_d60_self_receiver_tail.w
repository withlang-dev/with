//! expect-check-fail: mut receiver is too weak; compiler effects require `move fn`

// §9.1 / D60: the tail assignment yields a read of `self`, which moves the
// whole receiver out — exactly what the tail `self` does, so a `mut fn`
// receiver is too weak for it.

// D120: a struct of values is a value; this one is declared a resource
// so it still moves and still takes no copy.
resource type P { name: str }
extend P:
    mut fn reset -> P: self = P { name: "b".clone() }

fn main:
    var p = P { name: "a".clone() }
    print(p.reset().name)
