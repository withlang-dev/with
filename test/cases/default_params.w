fn greet(name: str, greeting: str = "Hello") -> i32:
    println("{greeting}, {name}!")
    0

fn add(a: i32, b: i32 = 10, c: i32 = 20) -> i32:
    a + b + c

fn main -> i32:
    greet("Alice")
    greet("Bob", "Hey")
    println(add(1))
    println(add(1, 2))
    println(add(1, 2, 3))
    0
