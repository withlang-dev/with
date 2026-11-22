//! expect-stdout: true
//! expect-stdout: true

// #1230: a fn-typed parameter named `check` shadows `std.builtins.check`.
// MirLower resolved the callee by name, so the indirect call inherited the
// builtin's signature and its `loc = src()` default — one extra `str`
// argument, rejected by the LLVM verifier ("Incorrect number of arguments").
// D29: the lexical binding wins; the call goes by the parameter's fn type.
error AgeError = Invalid(age: i32)

fn both(check: fn(i32) -> Result[Unit, AgeError]) -> bool: check(1).is_ok() and check(-1).is_err()

fn strict(age: i32) -> Result[Unit, AgeError]:
    if age < 0: return Err(.Invalid(age))
    Ok(())

fn either(check: fn(i32) -> bool) -> bool: check(1) and not check(-1)

fn positive(age: i32) -> bool: age > 0

fn main:
    print(f"{both(strict)}")
    print(f"{either(positive)}")
