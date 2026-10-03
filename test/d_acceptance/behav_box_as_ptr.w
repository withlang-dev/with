//! expect-stdout: 42
// §8 (#627): Box.as_ptr() returns the heap pointer, dereferenceable in unsafe.
fn main:
    let b = Box.new(42)
    let p = b.as_ptr()
    print_i32(unsafe { *p })
