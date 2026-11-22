//! expect-stdout: 43

// #3311: `pthread_self` is the program's name to use. The Windows runtime
// defined a bare `pthread_self` for the compiler's own use, so there a
// program's `fn pthread_self(x: i32) -> i32` did not compile ("no
// finalized FnAbi signature") and an export of the name did not link. The
// compiler now asks the runtime for its thread id by the runtime's name.
fn pthread_self(x: i32) -> i32: x + 1

fn main:
    print(pthread_self(42))
