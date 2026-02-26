type Token = Number(i32) | Plus | Minus | Star

fn show(t: Token) -> str:
    match t
        Number(n) ->
            if n == 0: "zero"
            else "num"
        Plus -> "+"
        Minus -> "-"
        Star -> "*"

fn main -> i32:
    println(show(Number(42)))
    println(show(Number(0)))
    println(show(Plus))
    println(show(Minus))
    println(show(Star))
