//! expect-stdout: 42
//! expect-stdout: 7

// #1766: a closure that captures nothing is a fat {fn, ctx} pair whose
// context is null; the C backend emits its body as a static function taking
// the context first, as the LLVM backend's closure convention does.
fn main:
    let twice = (x: i32) => x * 2
    print(twice(21))
    let seven = () => 7
    print(seven())
