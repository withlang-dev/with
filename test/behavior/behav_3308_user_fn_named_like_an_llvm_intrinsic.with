//! expect-stdout: FMA
//! expect-stdout: 4242
//! expect-stdout: FMA2
//! expect-stdout: 3
//! expect-stdout: EXP2
//! expect-stdout: 30
//! expect-stdout: LOG2
//! expect-stdout: 7
// #3308: codegen replaced a direct call with an LLVM intrinsic by the
// callee's name alone (`fma`, `exp2`, `log2`, …) when its first argument
// was an f64, whatever function Sema had resolved the call to. The callee
// is Sema's (D65); the math builtins reach codegen as their own intrinsic
// (D42) and need no name test.
fn fma(a: f64, b: f64, c: f64) -> f64:
    print("FMA")
    4242.0

type Pair { a: f64, b: f64 }

fn exp2(x: f64, scale: f64) -> f64:
    print("EXP2")
    x * scale

fn log2(x: f64) -> i32:
    print("LOG2")
    7

fn fma2(p: Pair) -> f64:
    print("FMA2")
    p.a + p.b

fn main:
    print(f"{fma(2.0, 3.0, 4.0)}")
    print(f"{fma2(Pair { a: 1.0, b: 2.0 })}")
    print(f"{exp2(3.0, 10.0)}")
    print(f"{log2(1024.0)}")
