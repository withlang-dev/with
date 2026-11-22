//! expect-stdout: 1
//! expect-stdout: 2
//! expect-stdout: Fizz
//! expect-stdout: 4
//! expect-stdout: Buzz
//! expect-stdout: 12
//! expect-stdout: 3
// D191 (§9.6): the indentation of a `|>` line decides what its left-hand
// side includes. At the match's column it pipes the whole match; indented
// under an operand it continues that operand.
fn main:
    for i in 1..=5:
        match (i % 3, i % 5):
            (0, 0) => "FizzBuzz"
            (0, _) => "Fizz"
            (_, 0) => "Buzz"
            _      => f"{i}"
        |> print
    let xs = [1, 2, 3]
    let total = xs
        |> map(it * 2)
        |> sum()
    print(total)
    let v = match 2:
        2 => "two"
        _ => "other"
    |> len
    print(v)
