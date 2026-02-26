fn main() -> i32 =
    let x = loop:
        break 42

    println(x)

    let mut i = 0
    let y = loop:
        if i == 5 then break i * 10
        i = i + 1

    println(y)
    0
