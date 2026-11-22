//! expect-stdout: ok

// #921 rig / MirLower fix: a borrow-returning method whose body has a
// statement before the field-borrow tail must NOT blank the borrowed field
// through the &Self receiver. The tail was lowered as a MOVE before the
// declared &T return proved it a borrow; the un-canceled §2.5.1 reset then
// zeroed the caller's field (std.build capability accessors returned
// pointers to zeroed ProcessRunner/ToolFs data in the native build runner).
type Inner { token: str }
type Outer { a: str, inner: Inner }
fn touch(t: &str) -> i64: t.len()
fn Outer.get(self: &Self) -> &Inner:
    touch(self.a)
    self.inner
fn check(i: &Inner) -> bool: i.token == "abc"
fn main:
    let o = Outer { a: "x", inner: Inner { token: "abc" } }
    if not check(o.get()):
        print("FAIL: borrowed field zeroed through receiver")
        return
    // The receiver must remain fully intact after the accessor.
    if o.inner.token == "abc" and o.a == "x":
        print("ok")
    else:
        print("FAIL: receiver mutated by accessor")
