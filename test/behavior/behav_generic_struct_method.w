//! expect-stdout: ok
type Wrapper[T] { value: T }

fn Wrapper.get(self: Wrapper[i32]) -> i32: self.value

fn main:
    let w: Wrapper[i32] = Wrapper{ value: 42 }
    let v = w.get()
    assert(v == 42)
    print("ok")
