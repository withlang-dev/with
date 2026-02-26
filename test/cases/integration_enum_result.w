// Integration test: enums with results and error handling
type Token = Number(i32) | Plus | Minus | Invalid

fn parse_token(s: str) -> Result[Token, str]:
    match s
        "+" -> Ok(Plus)
        "-" -> Ok(Minus)
        _ -> Err("unknown token")

fn token_value(t: Token) -> i32:
    match t
        Number(n) -> n
        Plus -> 1
        Minus -> 2
        Invalid -> -1

fn main -> i32:
    match parse_token("+")
        Ok(t) -> println(token_value(t))
        Err(e) -> println(e)
    match parse_token("-")
        Ok(t) -> println(token_value(t))
        Err(e) -> println(e)
    match parse_token("?")
        Ok(t) -> println(token_value(t))
        Err(e) -> println(e)
    0
