//! expect-error: 'first' is not callable
//! expect-error: 'first' is not callable
// D173 (§29.8): `first` resolves lexically to the local list, for every use;
// calling it is an error at the call, inside an interpolation as outside it,
// never a fallback to the module-scope `first` it shadows. (Inside the
// f-string it was accepted and crashed code generation, #2006.)
fn first() -> i32: 2

fn main:
    let first = [1, 2]
    print(first())
    print(f"{first()}")
