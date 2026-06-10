//! expect-stdout: ok

// Test: impl traits for user-defined types via prelude-provided traits.
// Note: impl for primitive types (i32, str) has a codegen limitation
// (sext ptr-to-i32); only struct/enum types work for now.

type MyInt { val: i32 }
type MyStr { val: str }

impl Eq for MyInt:    fn eq(self: MyInt, other:
    MyInt) -> bool:
        self.val == other.val

impl Debug for MyInt:    fn debug_str(self:
    MyInt) -> str:
        "MyInt"

impl Default for MyInt:
    fn default() -> MyInt:
        MyInt { val: 0 }

fn main:
    let a = MyInt { val: 42 }
    let b = MyInt { val: 42 }
    let c = MyInt { val: 7 }
    assert(a.eq(b))
    assert(not a.eq(c))
    assert(a.debug_str() == "MyInt")
    let d = MyInt.default()
    assert(d.val == 0)
    print("ok")
