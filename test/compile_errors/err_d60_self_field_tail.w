//! expect-check-fail: a field never moves out implicitly (§2.2, D32)

// §9.1 / D60 with D32: the tail assignment yields a read of `self.name`, and
// a field never moves out implicitly — the error the tail `self.name` gets.

type Holder { n: i32, name: str }
extend Holder:
    mut fn rename(s: str) -> str: self.name = s

fn main:
    var h = Holder { n: 0, name: "" }
    print(h.rename("x".clone()))
