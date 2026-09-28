//! expect-check-fail: va_start() reads the variable arguments of a function defined with a trailing `...` parameter; this body has none
//! expect-check-fail: va_start() starts a list that a variable holds
//! expect-check-fail: cannot advance the list in immutable binding `ap`
//! expect-check-fail: `arg[i8]()` reads a type no C caller passes through `...`: the default argument promotions pass an integer narrower than int as int
//! expect-check-fail: `arg[f32]()` reads a type no C caller passes through `...`: the default argument promotions pass a float as double
//! expect-check-fail: `arg[bool]()` reads a type no C caller passes through `...`: the default argument promotions pass a bool as int
//! expect-check-fail: `arg[str]()`: a variable argument is read as a promoted C scalar
//! expect-check-fail: reading a C variable argument requires unsafe context
//! expect-check-fail: unsafe function call requires unsafe context
//! expect-check-fail: `sum` is defined with `...`: it is called directly (under `unsafe`), never used as a value

// D75 (§16.2b.5): a function defined with a trailing `...` is unsafe to
// call; its body reads the list through `var ap = va_start()` and
// `ap.arg[T]()`. Each refusal below names the rule it applies.

unsafe fn sum(n: i32, ...) -> i32:
    var ap = va_start()
    var total = 0
    for i in 0..n:
        total = total + ap.arg[i32]()
    total

// No `...`: there is no list to start.
fn not_variadic(n: i32) -> i32:
    var ap = va_start()
    n

// A list lives in a variable; a temporary one would never end.
unsafe fn temporary_list(n: i32, ...) -> i32:
    sum(1, va_start())

// `arg[T]()` advances the list: a `let` list cannot.
unsafe fn let_list(n: i32, ...) -> i32:
    let ap = va_start()
    ap.arg[i32]()

// C's default argument promotions: a caller never passes these types.
unsafe fn narrow(n: i32, ...) -> i32:
    var ap = va_start()
    let a = ap.arg[i8]()
    let b = ap.arg[f32]()
    let c = ap.arg[bool]()
    let d = ap.arg[str]()
    0

// Nothing checks what the caller passed: the read is an unsafe operation.
fn safe_body(n: i32, ...) -> i32:
    var ap = va_start()
    ap.arg[i32]()

// A closure has its own frame and no list.
unsafe fn closure_start(n: i32, ...) -> i32:
    let f = () => va_start()
    0

fn main:
    let s = sum(1, 2)
    let f = sum
    print(s)
