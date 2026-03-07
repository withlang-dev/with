fn main:
    let result = read_file("nums.txt")
        |> lines |> map(parse) |> filter(|n| n % 2 == 0) |> sum
    println("Sum of evens: {result}")
