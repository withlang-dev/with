//! expect-stdout: ok

// Behavior test: generic traits — trait-bounded generics

trait Showable:    fn show(self:
    &Self) -> str

type Wrapper { value: i32 }
type Tag { label: str }

impl Showable for Wrapper:    fn show(self:
    Wrapper) -> str:
        "wrapper"

impl Showable for Tag:    fn show(self:
    Tag) -> str:
        self.label

fn display[T](x: T) -> str where T: Showable:
    x.show()

fn test_generic_bound_wrapper:
    let w = Wrapper { value: 42 }
    assert(display(w) == "wrapper")

fn test_generic_bound_tag:
    let t = Tag { label: "hello" }
    assert(display(t) == "hello")

fn is_wrapper_show[T](x: T) -> bool where T: Showable:
    x.show() == "wrapper"

fn test_generic_returns_bool:
    let w = Wrapper { value: 1 }
    let t = Tag { label: "test" }
    assert(is_wrapper_show(w) == true)
    assert(is_wrapper_show(t) == false)

fn main:
    test_generic_bound_wrapper()
    test_generic_bound_tag()
    test_generic_returns_bool()
    print("ok")
