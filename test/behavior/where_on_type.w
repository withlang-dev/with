//! expect-stdout: ok

// Where clause on type (parsed, not enforced at sema level)
type Wrapper[T] where T: Eq { value: T }

fn main:
    print("ok")
