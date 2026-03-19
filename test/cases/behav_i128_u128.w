//! expect-stdout: ok
extern fn print(s: str) -> void

fn main() -> i32:
    let x: i128 = 1
    let y = x + 1

    let ux: u128 = 40
    let uy = ux + 2

    if y == 2 and uy == 42:
        print("ok")
        return 0
    1
