// Test exhaustive enum matching with multiple variant types
type Token = enum {
    Number(i32),
    Plus,
    Minus,
    Eof,
}

fn token_to_str(t: Token) -> str =
    match t
        Token.Number(n) -> "number"
        Token.Plus -> "plus"
        Token.Minus -> "minus"
        Token.Eof -> "eof"

fn main() -> i32 =
    println(token_to_str(Token.Number(42)))
    println(token_to_str(Token.Plus))
    println(token_to_str(Token.Minus))
    println(token_to_str(Token.Eof))
    0
