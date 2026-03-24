//! expect-error: qualified enum pattern type 'Other' does not match subject type 'Shape'
enum Shape:
    Circle
    Rect

enum Other:
    Square
    Triangle

fn main:
    let shape = Shape.Circle
    let _ = match shape
        Other.Square => 1
        Shape.Circle => 2
