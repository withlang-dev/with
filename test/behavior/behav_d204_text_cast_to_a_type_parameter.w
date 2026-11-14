//! expect-stdout: 42 2.5 7
// §15.5 (D204): `text as T` where `T` is a type parameter converts to the
// type each instance binds.
fn read[T: Parse](text: str) -> T: text as T

fn main:
    let a: i32 = read("42")
    let b: f64 = read("2.5")
    let c: u8 = read("7")
    print(f"{a} {b} {c}")
