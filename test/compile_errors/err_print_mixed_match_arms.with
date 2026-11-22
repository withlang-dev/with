//! expect-error: format the arm as an f-string, print(f"{x}") style: f"{i}"

// D55 ruling 6 (§18.2): a `match` whose arms do not share a Display type
// yields nothing joinable; the fix-it is the f-string, never an implicit
// boxing join. This is the reference fizzbuzz's mixed-arm shape.

fn main:
    for i in 1..16:
        print(match (i % 3, i % 5):
            (0, 0) => "FizzBuzz"
            (0, _) => "Fizz"
            (_, 0) => "Buzz"
            _      => i
        )
