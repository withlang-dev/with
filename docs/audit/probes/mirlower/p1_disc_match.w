enum Color: i32:
    Red = 1
    Green = 2
    Blue = 4

fn classify(c: Color) -> str:
    match c:
        Color.Red => "red"
        Color.Green => "green"
        Color.Blue => "blue"
        _ => "other"

fn main:
    print(classify(Color.Red))
    print(classify(Color.Green))
    print(classify(Color.Blue))
