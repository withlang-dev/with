//! expect-stdout: one 1
//! expect-stdout: two0 1
//! expect-stdout: two7 1
//! expect-stdout: nested 1
//! expect-stdout: callee 1
//! expect-stdout: ok

// D82 (§2.2, §2.5.1): an explicit `move v.text` vacates the field and leaves
// `v` live; the destructor of `v` runs at the usual point and observes the
// field as its empty value. The count is the same whatever the sibling
// fields hold — a one-field value, a two-field one with `kind` zero or not,
// a nested member, and a vacate made inside a `mut fn` — because all-zero
// storage left by a vacate is a live value, never the moved-out sentinel.

var DROPS: i32 = 0

type Value { text: str }
impl Drop for Value:
    move fn drop():
        assert(self.text == "")
        DROPS += 1

type Tagged { kind: i32, text: str }
impl Drop for Tagged:
    move fn drop():
        assert(self.text == "")
        DROPS += 1
    mut fn take() -> str: move self.text

type Holder { kind: i32, value: Value }

fn one():
    var v = Value { text: "a".to_owned() }
    let t = move v.text
    assert(t == "a")

fn two(kind: i32):
    var v = Tagged { kind: kind, text: "b".to_owned() }
    let t = move v.text
    assert(t == "b")

fn nested():
    var h = Holder { kind: 0, value: Value { text: "c".to_owned() } }
    let t = move h.value.text
    assert(t == "c")

fn callee():
    var v = Tagged { kind: 0, text: "d".to_owned() }
    let t = v.take()
    assert(t == "d")

fn main:
    one()
    print(f"one {DROPS}")
    DROPS = 0
    two(0)
    print(f"two0 {DROPS}")
    DROPS = 0
    two(7)
    print(f"two7 {DROPS}")
    DROPS = 0
    nested()
    print(f"nested {DROPS}")
    DROPS = 0
    callee()
    print(f"callee {DROPS}")
    print("ok")
