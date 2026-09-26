//! expect-stdout: 4
//! expect-stdout: 7
//! expect-stdout: 9

// #1623 / D43: a `return` inside a let-else's else, a binding's value or a
// `with` body counts toward the inferred return type exactly as one inside
// an `if` does; `fn main:` here infers i32 and the MIR return local agrees.
fn get() -> Result[i32, str]: Ok(4)
fn pick(c: bool) -> i32:
    let v = if c: return 7 else: 2
    v
fn main:
    let Ok(x) = get() else: return 1
    print(x)
    print(pick(true))
    let Some(y) = Some(9) else:
        return 2
    print(y)
