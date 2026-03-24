//! expect-error: impl missing required associated type
trait Converter =
    type Output
    fn convert(self: Self, x: i32) -> Self.Output

type MyConv {}
impl Converter for MyConv =
    fn convert(self: MyConv, x: i32) -> i32: x * 2
