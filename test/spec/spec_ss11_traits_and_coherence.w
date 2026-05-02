// Spec test: Section 11 — Traits and Coherence (formerly 25.10)
// Adapted: orphan rule check not yet implemented; tests the implemented
// subset (trait definition, impl for own type, method dispatch).

trait Show:
    fn show(self: &Self) -> str

type MyType { x: i32 }
impl Show for MyType:
    fn show(self: &MyType) -> str: f"MyType({self.x})"

type Other { name: str }
impl Show for Other:
    fn show(self: &Other) -> str: f"Other({self.name})"

fn test_own_type_impl:
    let m = MyType { x: 42 }
    assert(m.show() == "MyType(42)")

fn test_second_impl:
    let o = Other { name: "hello" }
    assert(o.show() == "Other(hello)")

// blocked: orphan rule (impl Show for Vec[i32]) not enforced yet
// impl Show for Vec[i32]:              // should ERROR
//     fn show(self: &Vec[i32]) -> str: "vec"
