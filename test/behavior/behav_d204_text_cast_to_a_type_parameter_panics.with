//! expect-exit: 134
//! expect-stderr: panic: cannot parse u8 from "300": overflow
// §15.5 (D204): the panic of `text as T` names the type the instance binds.
fn read[T: Parse](text: str) -> T: text as T

fn main:
    let d: u8 = read("300")
    print(d)
