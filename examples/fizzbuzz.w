fn main:
    for i in 1..101:
        match (i % 3, i % 5)
            (0, 0) => print("FizzBuzz")
            (0, _) => print("Fizz")
            (_, 0) => print("Buzz")
            _ => print(i)
