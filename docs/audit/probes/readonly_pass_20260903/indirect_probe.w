use std.builtins.print
fn add(a: i32, b: i32) -> i32: a + b
fn apply(f: fn(i32, i32) -> i32, x: i32, y: i32) -> i32: f(x, y)
fn greet(name: str) -> str: "hi " ++ name
fn apply_s(f: fn(str) -> str, s: str) -> str: f(s)
extern "C" fn puts(s: *const u8) -> i32
fn main:
    let f = add
    print(apply(f, 3, 4).to_string())
    let adder = (a: i32, b: i32) => a * b
    print(apply(adder, 3, 4).to_string())
    let g = greet
    print(apply_s(g, "bob"))
    print(apply_s((s: str) => "yo " ++ s, "ann"))
