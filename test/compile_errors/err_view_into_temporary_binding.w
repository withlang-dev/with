//! expect-check-fail: binds a view into a temporary `Vec[str]` that is freed when this statement ends

// #962: `split` returns a Vec that dies at the end of the statement; `[1]`
// and `.get(1)` are views into it (D27). Binding the view read freed memory
// in safe code ("" or garbage, depending on the allocator's mood).
fn main:
    let line = "x\tdocs"
    let path = line.split("\t")[1]
    print(path)
