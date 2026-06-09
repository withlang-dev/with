//! skip-windows: issue #369: Windows custom fiber stack overflow diagnostic awaits async backend migration
//! expect-exit: 134
//! expect-stderr: fiber stack overflow
//! args: -O0

// Deep recursion on a small fiber stack at -O0.
// At higher optimization levels LLVM eliminates the stack usage.

fn deep(n: i32) -> i32:
    var buf: [64]i32 = [0; 64]
    buf[0] = n
    if n <= 0:
        return buf[0]
    buf[1] = deep(n - 1)
    buf[0] + buf[1]

@[stack_size(16384)]
async fn overflow() -> i32:
    deep(10000)

async fn main:
    let t = overflow()
    t.await
