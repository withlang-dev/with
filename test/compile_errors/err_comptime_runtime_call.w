//! expect-check-fail: is not comptime-callable: it reaches print -> with_println_str (an extern)

// D104 (§17.1): a `comptime fn` is a checked promise. `print` is a plain
// function whose body calls the extern `with_println_str`; the chain is
// named at the declaration, before anything evaluates `noisy`.
comptime fn noisy() -> i32:
    print("hi")
    0

fn main: print(noisy())
