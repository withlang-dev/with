//! expect-stdout: 6
//! expect-stdout: 8 10
//! expect-stdout: 12
//! expect-stdout: 14
//! expect-stdout: 20 22
//! expect-stdout: 24 true
//! expect-stdout: 26
//! expect-stdout: saw 15
//! expect-stdout: Some(28) Some(15)

// D65 (§12): a function named as a value becomes a With callable `fn(...)`
// or an `extern "C" fn` pointer by the type Sema gives the expression.
// MIR records the callable case on the constant and codegen builds the
// adapter there; codegen had guessed it from a pointer meeting `{ptr, ptr}`.
// Taking its address (`&f` into `*const fn`, `f as *const u8`) is the code
// address, which a callable adapter would have corrupted; a pipeline stage
// named by a function is the call's callee; a named function given to an
// inline-expanded combinator (Option.map / inspect / filter) is called as the
// callable value it is.

type Holder:
    f: fn(i32) -> i32

fn double(x: i32) -> i32: x * 2
fn apply(f: fn(i32) -> i32, x: i32) -> i32: f(x)
fn apply_c(f: extern "C" fn(i32) -> i32, x: i32) -> i32: f(x)
fn apply_ptr(f: *const fn(i32) -> i32, x: i32) -> i32: f(x)
fn nonneg(x: &i32) -> bool: *x >= 0
fn show(x: &i32): print(f"saw {*x}")

fn main:
    print(f"{apply(double, 3)}")
    let g: fn(i32) -> i32 = double
    let h = double
    print(f"{g(4)} {h(5)}")
    let holder = Holder { f: double }
    print(f"{(holder.f)(6)}")
    print(f"{apply_c(double, 7)}")
    var fs: List[fn(i32) -> i32] = List.new()
    fs.push(double)
    fs.push(g)
    print(f"{fs[0](10)} {fs[1](11)}")
    // A code address, not the callable: `&f` into `*const fn`, and a cast.
    let code: *const fn(i32) -> i32 = &double
    let raw = double as *const u8
    print(f"{apply_ptr(code, 12)} {raw != null}")
    print(f"{13 |> double}")
    let o: Option[i32] = Some(14)
    let shown = Some(15).inspect(show)
    print(f"{o.map(double):?} {shown.filter(nonneg):?}")
