// Test exhaustive enum matching with multiple variant types
type Token = Number(i32) | Plus | Minus | Eof

fn token_to_str(t: Token) -> str:
    match t
        Number(n) -> "number"
        Plus -> "plus"
        Minus -> "minus"
        Eof -> "eof"

fn main -> i32:
    println(token_to_str(Number(42)))
    println(token_to_str(Plus))
    println(token_to_str(Minus))
    println(token_to_str(Eof))
