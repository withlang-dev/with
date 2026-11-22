//! expect-error: integer literal does not fit expected type

// #2567 (§4.5): a literal at a distinct demand is checked at the underlying
// type's width.
type Small = distinct i8
fn big() -> Small: 300
fn main: print_i32(big().value)
