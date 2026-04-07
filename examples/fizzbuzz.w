fn main:
    for i in 1..101:
        print( match (i % 3, i % 5)
            (0, 0) => "FizzBuzz"
            (0, _) => "Fizz"
            (_, 0) => "Buzz"
            _      => i
        )
