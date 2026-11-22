//! expect-debug-alloc: peak live bytes=
//! expect-stdout: 4 2

// #2407: the debug allocator reports the peak live memory and its shape —
// bytes and blocks at the peak, by origin kind and by size class, and the
// largest requests — beside its leak report, so a program's memory high
// point can be read without a sampler.
fn main:
    let xs = [1, 2, 3, 4]
    let names = ["a".to_owned(), "b".to_owned()]
    print(f"{xs.len()} {names.len()}")
