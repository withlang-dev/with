//! expect-stdout: 101
//! expect-stdout: USERFN
//! expect-stdout: 4242
//! expect-stdout: 3
// #3307: §17.6a: "A function of the same name defined in scope takes
// precedence; the builtin is reached only when ordinary resolution finds
// nothing. An `extern fn` declaration of a builtin's name does not shadow
// it". Sema asked whether any module declares an extern of the name (the
// engines declare `exp`, `sqrt` and fifteen more), not whether the call
// resolved to one, so the program's own `exp` lost to the builtin.
type Arr { x: f64 }

fn exp(a: Arr) -> Arr: Arr { x: a.x + 100.0 }

fn sqrt(x: f64) -> f64:
    print("USERFN")
    4242.0

fn main:
    let a = exp(Arr { x: 1.0 })
    print(f"{a.x}")
    print(f"{sqrt(9.0)}")
    let nine = 9.0
    print(f"{nine.sqrt()}")
