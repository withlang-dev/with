//! expect-exit: 0

// D27 E1: resolved operators materialize Copy pointees only when their
// selected operand types demand owned values. An exact `&*const T` dereference
// remains safe-reference dereference and produces the pointer stored there.

fn main:
    let values = [10, 20, 30]
    let indices = [2, 0]
    assert(values[indices[0]] == 30)

    let x = 7
    let p = &raw const x
    let pointers = [p, p]
    let advanced = pointers[0] + 0
    assert(advanced == p)
    assert(unsafe *advanced == 7)

    let exact = *pointers[0]
    assert(exact == p)
    assert(unsafe *(pointers[0] as *const i32) == 7)
