//! expect-stdout: 1 2 0

// §4.9, §4.2.1 (D114): a literal final expression of a function returning
// `Result[i32, E]` is the `Ok` payload, an i32; it was the isize default,
// refused as a narrowing.
fn a(t: &str) -> Result[i32, str]:
    if t == "bad": return Err(t)
    1

fn b() -> Result[i32, str]: 2

fn c(t: &str) -> Result[i32, str]:
    for p in t.split(","):
        if p == "bad": return Err(p)
    0

fn main:
    print(f"{a("x").unwrap()} {b().unwrap()} {c("y").unwrap()}")
