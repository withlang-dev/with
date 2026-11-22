//! expect-error: manual extern function call requires unsafe context; 'with_fs_exists' is the compiler's own runtime (D30), not an interface for programs: call the std API that wraps it

// D30: `with_*` symbols are the compiler's runtime; a program never names
// one. A program that declares one by hand still needs `unsafe` to call it
// (it is a manual extern), and the error names the remedy.
extern fn with_fs_exists(path: &str) -> i32

fn main:
    print(f"{with_fs_exists("x")}")
