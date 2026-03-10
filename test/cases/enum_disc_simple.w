extern fn print(s: str) -> void
extern fn int_to_string(n: i32) -> str

type Color: i32 = Red = 1 | Green = 2 | Blue = 4

fn main:
    let r = Color.Red
    let g = Color.Green
    let b = Color.Blue
    print(int_to_string(r))
    print(int_to_string(g))
    print(int_to_string(b))
    if r == 1:
        print("red is 1")
    if g == Color.Green:
        print("green match")
    let sum = r + g + b
    print(int_to_string(sum))
