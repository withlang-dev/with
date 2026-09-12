//! expect-check-fail: left operand of ++ must be str
type Wrapper[T] { value: T }
fn main:
    let value: Wrapper[str] = Wrapper { value: "hello" }
    print(value ++ "!")
