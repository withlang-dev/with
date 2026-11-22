//! expect-check-fail: is not comptime-callable: it reaches helper -> getpid (an extern)

// D104 (§17.1): a `comptime fn` is checked statically at its declaration —
// every callee must resolve and run at compile time — so a plain callee
// that reaches an extern (FFI, forbidden at compile time) is refused there,
// naming the chain, whether or not anything ever evaluates `build`: main
// calls it at run time only.
extern fn getpid() -> i32

fn helper(n: i32) -> i32: n + getpid()
comptime fn build(n: i32) -> i32: helper(n) + 1

fn main: print(build(2))
